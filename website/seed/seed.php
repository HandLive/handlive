<?php
/**
 * Seed the HandLive website from seed/content: Polylang languages and URL settings, media from the hub's
 * docs, blog posts and pages in English and Vietnamese linked as translations, and site options.
 * Idempotent: posts and pages are matched by slug and updated in place, media by its source path.
 *
 * Run by bin/setup.sh: wp eval-file /seed/seed.php --user=<admin>
 * Content placeholders: {{release}} {{github}} {{post:<key>}} {{page:<key>}} {{id:<docs path>}} {{src:<docs path>}}.
 *
 * @package HandLive
 */

if ( ! defined( 'WP_CLI' ) || ! function_exists( 'PLL' ) ) {
	fwrite( STDERR, "Run with WP-CLI, with Polylang active.\n" );
	exit( 1 );
}

require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/media.php';
require_once ABSPATH . 'wp-admin/includes/image.php';

const HL_CONTENT = '/seed/content';
const HL_DOCS    = '/hub-docs';

$site = json_decode( (string) file_get_contents( HL_CONTENT . '/site.json' ), true );
$langs = array_column( $site['languages'], 'slug' );

hl_languages( $site['languages'] );
hl_polylang_options();
hl_remove_sample_content();
hl_public_author();
$news = hl_category( $site['category'] );

// Pass 1: every post and page exists with its language and translation links, so links can be resolved.
$ids = array( 'post' => array(), 'page' => array() );
foreach ( array( 'post' => $site['posts'], 'page' => $site['pages'] ) as $type => $items ) {
	foreach ( $items as $item ) {
		foreach ( $langs as $lang ) {
			$ids[ $type ][ $item['key'] ][ $lang ] = hl_ensure( $type, $lang, $item[ $lang ], $item['date'] ?? '' );
		}
		pll_save_post_translations( $ids[ $type ][ $item['key'] ] );
	}
}

// Pass 2: content, excerpts, covers, categories.
foreach ( array( 'post' => $site['posts'], 'page' => $site['pages'] ) as $type => $items ) {
	foreach ( $items as $item ) {
		foreach ( $langs as $lang ) {
			$id   = $ids[ $type ][ $item['key'] ][ $lang ];
			$data = $item[ $lang ];
			$post = array(
				'ID'           => $id,
				'post_title'   => $data['title'],
				'post_excerpt' => $data['excerpt'] ?? '',
			);
			if ( ! empty( $data['file'] ) ) {
				$raw                  = (string) file_get_contents( HL_CONTENT . '/' . $data['file'] );
				$post['post_content'] = hl_resolve( $raw, $lang, $ids, $site['links'] );
			}
			wp_update_post( wp_slash( $post ) );
			if ( ! empty( $data['cover'] ) ) {
				set_post_thumbnail( $id, hl_media( $data['cover'] )['id'] );
			}
			if ( 'post' === $type ) {
				wp_set_post_categories( $id, array( $news[ $lang ] ) );
			}
		}
	}
}

update_option( 'show_on_front', 'page' );
update_option( 'page_on_front', $ids['page']['home']['en'] );
update_option( 'page_for_posts', $ids['page']['blog']['en'] );
update_option( 'blogname', 'HandLive' );
update_option( 'blogdescription', 'Never miss a signal.' );
update_option( 'date_format', 'F j, Y' );
update_option( 'posts_per_page', 9 );
update_option( 'default_comment_status', 'closed' );
update_option( 'default_ping_status', 'closed' );
set_theme_mod( 'handlive_page_privacy', $ids['page']['privacy']['en'] );

WP_CLI::success( sprintf( 'Seeded %d posts and %d pages in %s.', count( $ids['post'] ), count( $ids['page'] ), implode( ', ', $langs ) ) );

/**
 * Add the site's languages to Polylang (English first: the default).
 *
 * @param array $languages From site.json.
 */
function hl_languages( array $languages ): void {
	foreach ( $languages as $order => $lang ) {
		if ( PLL()->model->languages->get( $lang['slug'] ) ) {
			continue;
		}
		$result = PLL()->model->languages->add(
			array(
				'name'       => $lang['name'],
				'slug'       => $lang['slug'],
				'locale'     => $lang['locale'],
				'rtl'        => false,
				'term_group' => $order,
				'flag'       => $lang['flag'],
			)
		);
		if ( is_wp_error( $result ) ) {
			WP_CLI::error( 'Polylang: ' . $result->get_error_message() );
		}
	}
	// Content that predates Polylang (the default category) gets the default language.
	$uncategorized = (int) get_option( 'default_category' );
	if ( $uncategorized && ! pll_get_term_language( $uncategorized ) ) {
		pll_set_term_language( $uncategorized, 'en' );
	}
}

/**
 * URLs: English at the root, other languages under /<slug>/ (front pages at "/" and "/vi/" rather than
 * their page slugs); no browser redirect; media shared by languages.
 */
function hl_polylang_options(): void {
	$options = array(
		'default_lang'  => 'en',
		'force_lang'    => 1,
		'hide_default'  => true,
		'rewrite'       => true,
		'browser'       => false,
		'redirect_lang' => true,
		'media_support' => false,
	);
	foreach ( $options as $key => $value ) {
		$error = PLL()->options->set( $key, $value );
		if ( is_wp_error( $error ) && $error->has_errors() ) {
			WP_CLI::warning( "Polylang option $key: " . $error->get_error_message() );
		}
	}
	PLL()->options->save();
}

/**
 * WordPress's sample post, page, draft privacy page and comment.
 */
function hl_remove_sample_content(): void {
	foreach ( array( 'hello-world' => 'post', 'sample-page' => 'page', 'privacy-policy' => 'page' ) as $slug => $type ) {
		$found = get_page_by_path( $slug, OBJECT, $type );
		if ( $found ) {
			wp_delete_post( $found->ID, true );
		}
	}
	update_option( 'wp_page_for_privacy_policy', 0 );
}

/**
 * The admin's public name. `wp core install` makes the login name the display name and the author slug,
 * which feeds (`dc:creator`) would print; the site speaks as HandLive.
 */
function hl_public_author(): void {
	$updated = wp_update_user(
		array(
			'ID'            => get_current_user_id(),
			'display_name'  => 'HandLive',
			'nickname'      => 'HandLive',
			'user_nicename' => 'handlive',
		)
	);
	if ( is_wp_error( $updated ) ) {
		WP_CLI::error( 'Could not set the public author name: ' . $updated->get_error_message() );
	}
}

/**
 * The news category in every language, linked as translations.
 *
 * @param array $names Language slug => category name.
 * @return array Language slug => term id.
 */
function hl_category( array $names ): array {
	$ids = array();
	foreach ( $names as $lang => $name ) {
		$slug = sanitize_title( $name );
		$term = get_term_by( 'slug', $slug, 'category' );
		$id   = $term ? (int) $term->term_id : (int) wp_insert_term( $name, 'category', array( 'slug' => $slug ) )['term_id'];
		pll_set_term_language( $id, $lang );
		$ids[ $lang ] = $id;
	}
	pll_save_term_translations( $ids );
	return $ids;
}

/**
 * Find a post or page by slug, or create it; set its language. Returns its id.
 *
 * @param string $type Post type.
 * @param string $lang Language slug.
 * @param array  $data title, slug.
 * @param string $date Publication date (posts).
 */
function hl_ensure( string $type, string $lang, array $data, string $date ): int {
	$found = get_page_by_path( $data['slug'], OBJECT, $type );
	if ( $found ) {
		$id = (int) $found->ID;
	} else {
		$args = array(
			'post_type'   => $type,
			'post_status' => 'publish',
			'post_title'  => $data['title'],
			'post_name'   => $data['slug'],
		);
		if ( $date ) {
			$args['post_date'] = $date;
		}
		$id = wp_insert_post( wp_slash( $args ), true );
		if ( is_wp_error( $id ) ) {
			WP_CLI::error( "Could not create $type {$data['slug']}: " . $id->get_error_message() );
		}
	}
	pll_set_post_language( $id, $lang );
	return (int) $id;
}

/**
 * Replace the content placeholders for one language.
 *
 * @param string $content Block markup.
 * @param string $lang    Language slug.
 * @param array  $ids     Post and page ids by type, key and language.
 * @param array  $links   External links from site.json.
 */
function hl_resolve( string $content, string $lang, array $ids, array $links ): string {
	return preg_replace_callback(
		'/\{\{(release|github|post|page|id|src)(?::([^}]+))?\}\}/',
		function ( $m ) use ( $lang, $ids, $links ) {
			switch ( $m[1] ) {
				case 'release':
				case 'github':
					return $links[ $m[1] ];
				case 'post':
				case 'page':
					// get_permalink() has no language context under WP-CLI, so build the URL from the
					// language's home ("/" or "/vi/") and the slug.
					$slug = (string) get_post_field( 'post_name', $ids[ $m[1] ][ $m[2] ][ $lang ] );
					return trailingslashit( pll_home_url( $lang ) ) . $slug . '/';
				case 'id':
					return (string) hl_media( $m[2] )['id'];
				default:
					return hl_media( $m[2] )['url'];
			}
		},
		$content
	);
}

/**
 * Import a file from the hub's docs into the media library once; later calls reuse it.
 *
 * @param string $path Path under docs/, e.g. "screenshots/ios/04-sms-conversation.en.png".
 * @return array{id:int,url:string}
 */
function hl_media( string $path ): array {
	static $cache = array();
	if ( isset( $cache[ $path ] ) ) {
		return $cache[ $path ];
	}
	$existing = get_posts(
		array(
			'post_type'   => 'attachment',
			'post_status' => 'inherit',
			'meta_key'    => '_handlive_source',
			'meta_value'  => $path,
			'fields'      => 'ids',
			'numberposts' => 1,
			'lang'        => '',
		)
	);
	if ( $existing ) {
		$id = (int) $existing[0];
	} else {
		$source = HL_DOCS . '/' . $path;
		if ( ! is_readable( $source ) ) {
			WP_CLI::error( "Missing media file: docs/$path" );
		}
		$tmp = wp_tempnam( basename( $path ) );
		copy( $source, $tmp );
		$id = media_handle_sideload( array( 'name' => basename( $path ), 'tmp_name' => $tmp ), 0 );
		if ( is_wp_error( $id ) ) {
			WP_CLI::error( "Could not import docs/$path: " . $id->get_error_message() );
		}
		update_post_meta( $id, '_handlive_source', $path );
	}
	$cache[ $path ] = array(
		'id'  => (int) $id,
		'url' => (string) wp_get_attachment_url( $id ),
	);
	return $cache[ $path ];
}
