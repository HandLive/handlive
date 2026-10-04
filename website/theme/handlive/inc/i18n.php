<?php
/**
 * Language helpers on top of Polylang (English is the default language, Vietnamese the second).
 * Every helper still works when Polylang is off: the site then behaves as English only.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;

/**
 * Slug of the language being shown: "en" or "vi".
 */
function handlive_lang(): string {
	$slug = function_exists( 'pll_current_language' ) ? pll_current_language( 'slug' ) : '';
	return $slug ? $slug : 'en';
}

/**
 * Home URL of the current language ("/" for English, "/vi/" for Vietnamese).
 */
function handlive_home_url(): string {
	return function_exists( 'pll_home_url' ) ? pll_home_url() : home_url( '/' );
}

/**
 * Permalink of a page in the current language; falls back to the page itself when it has no translation.
 *
 * @param int $page_id Page in any language.
 */
function handlive_page_url( int $page_id ): string {
	if ( ! $page_id ) {
		return '';
	}
	$translated = function_exists( 'pll_get_post' ) ? pll_get_post( $page_id ) : 0;
	return (string) get_permalink( $translated ? $translated : $page_id );
}

/**
 * Page id stored by the seed script (theme mods hold the English page; translations come from Polylang).
 *
 * @param string $key "privacy".
 */
function handlive_page_id( string $key ): int {
	return (int) get_theme_mod( 'handlive_page_' . $key, 0 );
}

/**
 * Blog index URL in the current language.
 */
function handlive_blog_url(): string {
	$blog = (int) get_option( 'page_for_posts' );
	return $blog ? handlive_page_url( $blog ) : handlive_home_url();
}

/**
 * Post date in the reader's language: "September 30, 2026" in English, "30/9/2026" in Vietnamese.
 * Numeric in Vietnamese so the page needs no WordPress language pack for month names.
 *
 * @param int|WP_Post|null $post Post.
 */
function handlive_date( $post = null ): string {
	$format = 'vi' === handlive_lang() ? 'j/n/Y' : 'F j, Y';
	return (string) get_the_date( $format, $post );
}

/**
 * Language switcher: one link per language, the current one marked with aria-current.
 */
function handlive_language_switcher(): void {
	if ( ! function_exists( 'pll_the_languages' ) ) {
		return;
	}
	$languages = pll_the_languages(
		array(
			'raw'                    => 1,
			'hide_if_no_translation' => 0,
			'hide_current'           => 0,
		)
	);
	if ( empty( $languages ) || count( $languages ) < 2 ) {
		return;
	}
	echo '<ul class="hl-lang" aria-label="' . esc_attr__( 'Language', 'handlive' ) . '">';
	foreach ( $languages as $lang ) {
		$current = ! empty( $lang['current_lang'] );
		printf(
			'<li><a href="%1$s" hreflang="%2$s" lang="%2$s" title="%3$s"%4$s>%5$s</a></li>',
			esc_url( $lang['url'] ),
			esc_attr( $lang['slug'] ),
			esc_attr( $lang['name'] ),
			$current ? ' aria-current="true"' : '',
			esc_html( strtoupper( $lang['slug'] ) )
		);
	}
	echo '</ul>';
}

/**
 * Primary navigation: the menu assigned in Appearance → Menus, or the built-in links when none is set.
 */
function handlive_primary_nav(): void {
	if ( has_nav_menu( 'primary' ) ) {
		wp_nav_menu(
			array(
				'theme_location' => 'primary',
				'container'      => false,
				'menu_class'     => 'hl-nav__list',
				'depth'          => 1,
			)
		);
		return;
	}
	$links = array(
		array( handlive_home_url() . '#features', __( 'Features', 'handlive' ) ),
		array( handlive_page_url( handlive_page_id( 'privacy' ) ), __( 'Privacy', 'handlive' ) ),
		array( handlive_blog_url(), __( 'Blog', 'handlive' ) ),
		array( HANDLIVE_GITHUB_URL, 'GitHub' ),
	);
	echo '<ul class="hl-nav__list">';
	foreach ( $links as $link ) {
		if ( $link[0] ) {
			printf( '<li><a href="%s">%s</a></li>', esc_url( $link[0] ), esc_html( $link[1] ) );
		}
	}
	echo '</ul>';
}
