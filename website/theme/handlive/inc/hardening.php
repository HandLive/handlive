<?php
/**
 * Keep the site's one author out of public view, and drop head links the site doesn't use.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;

// The users REST endpoints list the admin's login name to anyone; only signed-in users need them.
add_filter(
	'rest_endpoints',
	function ( array $endpoints ): array {
		if ( is_user_logged_in() ) {
			return $endpoints;
		}
		foreach ( array_keys( $endpoints ) as $route ) {
			if ( str_starts_with( $route, '/wp/v2/users' ) ) {
				unset( $endpoints[ $route ] );
			}
		}
		return $endpoints;
	}
);

// Author archives (/?author=1, /author/<login>/) reveal the login name and duplicate the blog; send them to
// the blog. Priority 1 runs before redirect_canonical (10), which would otherwise redirect /?author=1 to
// /author/<login>/ first.
add_action(
	'template_redirect',
	function () {
		if ( is_author() ) {
			wp_safe_redirect( handlive_blog_url(), 301 );
			exit;
		}
	},
	1
);

// No users sitemap for the same reason.
add_filter(
	'wp_sitemaps_add_provider',
	function ( $provider, string $name ) {
		return 'users' === $name ? false : $provider;
	},
	10,
	2
);

// Head links to things nginx blocks or the site doesn't offer: XML-RPC discovery, WordPress version, per-post comment feeds.
remove_action( 'wp_head', 'rsd_link' );
remove_action( 'wp_head', 'wp_generator' );
remove_action( 'wp_head', 'feed_links_extra', 3 );
