<?php
/**
 * Description and social sharing tags. Canonical links come from WordPress, hreflang links from Polylang.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;

/**
 * Short description of the current view: the excerpt of a post or page, otherwise the product one-liner.
 */
function handlive_meta_description(): string {
	if ( is_singular() ) {
		$post = get_queried_object();
		if ( $post instanceof WP_Post && has_excerpt( $post ) ) {
			return wp_strip_all_tags( get_the_excerpt( $post ) );
		}
	}
	return __( 'Your Android phone\'s clipboard, SMS, and calls, on your Mac, iPhone, and iPad. End-to-end encrypted, no account, open source.', 'handlive' );
}

// Document titles in the reader's language: the tagline on front pages, and the not-found title
// (WordPress core strings need a language pack the site doesn't install).
add_filter(
	'document_title_parts',
	function ( array $parts ): array {
		if ( is_front_page() ) {
			$parts['tagline'] = __( 'Never miss a signal.', 'handlive' );
		} elseif ( is_404() ) {
			$parts['title'] = __( 'Page not found', 'handlive' );
		}
		return $parts;
	}
);

add_action(
	'wp_head',
	function () {
		$title       = wp_get_document_title();
		$description = handlive_meta_description();
		$image       = get_theme_file_uri( 'assets/img/social-preview.png' );
		if ( is_singular() && has_post_thumbnail() ) {
			$image = (string) get_the_post_thumbnail_url( null, 'full' );
		}
		$url    = is_singular() ? (string) get_permalink() : handlive_home_url();
		$locale = 'vi' === handlive_lang() ? 'vi_VN' : 'en_US';
		$tags   = array(
			'description'         => $description,
			'og:type'             => is_single() ? 'article' : 'website',
			'og:site_name'        => 'HandLive',
			'og:title'            => $title,
			'og:description'      => $description,
			'og:url'              => $url,
			'og:image'            => $image,
			'og:locale'           => $locale,
			'twitter:card'        => 'summary_large_image',
		);
		foreach ( $tags as $key => $value ) {
			$attr = str_starts_with( $key, 'og:' ) ? 'property' : 'name';
			printf( '<meta %s="%s" content="%s">' . "\n", $attr, esc_attr( $key ), esc_attr( $value ) );
		}
	},
	5
);
