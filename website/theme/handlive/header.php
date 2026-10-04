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
			<a class="hl-button hl-button--small" href="<?php echo esc_url( HANDLIVE_RELEASE_URL ); ?>"><?php esc_html_e( 'Get the Beta', 'handlive' ); ?></a>
		</nav>
	</div>
</header>
