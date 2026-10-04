<?php
/**
 * Theme setup: supports, menus, text domain, styles, head links.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;

const HANDLIVE_VERSION     = '1.0.0';
const HANDLIVE_GITHUB_URL  = 'https://github.com/HandLive';
const HANDLIVE_RELEASE_URL = 'https://github.com/HandLive/handlive/releases/tag/v0.1.0-beta.1';

add_action(
	'after_setup_theme',
	function () {
		load_theme_textdomain( 'handlive', get_template_directory() . '/languages' );
		add_theme_support( 'title-tag' );
		add_theme_support( 'post-thumbnails' );
		add_theme_support( 'responsive-embeds' );
		add_theme_support( 'html5', array( 'search-form', 'gallery', 'caption', 'style', 'script', 'navigation-widgets' ) );
		add_theme_support( 'editor-styles' );
		add_editor_style( 'assets/css/site.css' );
		register_nav_menus( array( 'primary' => __( 'Primary menu', 'handlive' ) ) );
		set_post_thumbnail_size( 1280, 640, true );
	}
);

add_action(
	'wp_enqueue_scripts',
	function () {
		wp_enqueue_style( 'handlive', get_theme_file_uri( 'assets/css/site.css' ), array(), handlive_asset_version( 'assets/css/site.css' ) );
		wp_enqueue_script( 'handlive', get_theme_file_uri( 'assets/js/site.js' ), array(), handlive_asset_version( 'assets/js/site.js' ), array( 'strategy' => 'defer' ) );
	}
);

/**
 * Cache-busting version: the theme version plus the file's modification time (nginx caches assets 30 days).
 *
 * @param string $path Path inside the theme.
 */
function handlive_asset_version( string $path ): string {
	$mtime = @filemtime( get_theme_file_path( $path ) ); // phpcs:ignore WordPress.PHP.NoSilencedErrors
	return HANDLIVE_VERSION . ( $mtime ? '.' . $mtime : '' );
}

// Font preload and icons. The site has no custom site icon, so the theme supplies the brand mark.
add_action(
	'wp_head',
	function () {
		// The two weights every page uses above the fold: Black for titles, Bold for card headings.
		foreach ( array( 'black', 'bold' ) as $weight ) {
			printf(
				'<link rel="preload" href="%s" as="font" type="font/woff2" crossorigin>' . "\n",
				esc_url( get_theme_file_uri( "assets/fonts/be-vietnam-pro-$weight.woff2" ) )
			);
		}
		if ( ! has_site_icon() ) {
			printf( '<link rel="icon" href="%s" type="image/svg+xml">' . "\n", esc_url( get_theme_file_uri( 'assets/img/favicon.svg' ) ) );
			printf( '<link rel="apple-touch-icon" href="%s">' . "\n", esc_url( get_theme_file_uri( 'assets/img/apple-touch-icon.png' ) ) );
		}
		echo '<meta name="theme-color" content="#fff6ee" media="(prefers-color-scheme: light)">' . "\n";
		echo '<meta name="theme-color" content="#1c1319" media="(prefers-color-scheme: dark)">' . "\n";
	},
	2
);

// Emoji scripts add weight for nothing on this site.
remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
remove_action( 'wp_print_styles', 'print_emoji_styles' );

/**
 * The brand lockup as a picture that follows the light and dark appearance.
 *
 * @param string $class Extra class for the img element.
 */
function handlive_lockup( string $class = '' ): void {
	printf(
		'<picture><source srcset="%1$s" media="(prefers-color-scheme: dark)"><img class="%3$s" src="%2$s" alt="HandLive" width="160" height="36"></picture>',
		esc_url( get_theme_file_uri( 'assets/img/lockup-on-dark.svg' ) ),
		esc_url( get_theme_file_uri( 'assets/img/lockup.svg' ) ),
		esc_attr( $class )
	);
}

/**
 * The footer lockup: the footer is always plum, so it always uses the on-dark version.
 */
function handlive_lockup_on_dark(): void {
	printf(
		'<img class="hl-footer__logo" src="%s" alt="HandLive" width="160" height="36">',
		esc_url( get_theme_file_uri( 'assets/img/lockup-on-dark.svg' ) )
	);
}
