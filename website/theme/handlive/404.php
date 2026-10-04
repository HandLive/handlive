<?php
/**
 * Not found.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
get_header();
?>
<main id="main" class="hl-main">
	<div class="hl-container hl-article hl-notfound">
		<h1 class="hl-article__title"><?php esc_html_e( 'This page went off the air.', 'handlive' ); ?></h1>
		<p class="hl-lead"><?php esc_html_e( 'The link may be old, or the page has moved.', 'handlive' ); ?></p>
		<p><a class="hl-button" href="<?php echo esc_url( handlive_home_url() ); ?>"><?php esc_html_e( 'Go to the Home Page', 'handlive' ); ?></a></p>
	</div>
</main>
<?php
get_footer();
