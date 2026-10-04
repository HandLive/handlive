<?php
/**
 * Site header: lockup, primary navigation, language switcher, call to action.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo( 'charset' ); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<a class="hl-skip" href="#main"><?php esc_html_e( 'Skip to content', 'handlive' ); ?></a>
<header class="hl-header">
	<div class="hl-container hl-header__inner">
		<a class="hl-brand" href="<?php echo esc_url( handlive_home_url() ); ?>" rel="home">
			<?php handlive_lockup( 'hl-brand__logo' ); ?>
		</a>
		<button class="hl-menu-toggle" type="button" aria-expanded="false" aria-controls="hl-nav">
			<span class="hl-menu-toggle__bar" aria-hidden="true"></span>
			<span class="screen-reader-text"><?php esc_html_e( 'Menu', 'handlive' ); ?></span>
		</button>
		<nav id="hl-nav" class="hl-nav" aria-label="<?php esc_attr_e( 'Primary', 'handlive' ); ?>">
			<?php handlive_primary_nav(); ?>
			<?php handlive_language_switcher(); ?>
			<button class="hl-theme-toggle" type="button" aria-label="<?php esc_attr_e( 'Dark Mode', 'handlive' ); ?>" aria-pressed="false">
				<svg class="hl-theme-toggle__sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/></svg>
				<svg class="hl-theme-toggle__moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>
			</button>
			<a class="hl-button hl-button--small" href="<?php echo esc_url( HANDLIVE_RELEASE_URL ); ?>"><?php esc_html_e( 'Get the Beta', 'handlive' ); ?></a>
		</nav>
	</div>
</header>
