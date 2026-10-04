<?php
/**
 * Site footer: lockup, tagline, links, licenses.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
$privacy = handlive_page_url( handlive_page_id( 'privacy' ) );
?>
<footer class="hl-footer">
	<div class="hl-container hl-footer__inner">
		<div class="hl-footer__brand">
			<?php handlive_lockup_on_dark(); ?>
			<p class="hl-footer__tagline"><?php esc_html_e( 'Never miss a signal.', 'handlive' ); ?></p>
		</div>
		<ul class="hl-footer__links">
			<?php if ( $privacy ) : ?>
				<li><a href="<?php echo esc_url( $privacy ); ?>"><?php esc_html_e( 'Privacy', 'handlive' ); ?></a></li>
			<?php endif; ?>
			<li><a href="<?php echo esc_url( handlive_blog_url() ); ?>"><?php esc_html_e( 'Blog', 'handlive' ); ?></a></li>
			<li><a href="<?php echo esc_url( HANDLIVE_GITHUB_URL ); ?>">GitHub</a></li>
			<li><a href="<?php echo esc_url( HANDLIVE_RELEASE_URL ); ?>"><?php esc_html_e( 'Get the Beta', 'handlive' ); ?></a></li>
		</ul>
		<p class="hl-footer__legal">
			<?php esc_html_e( 'HandLive is open source: the apps under Apache-2.0, this website under GPL-2.0-or-later.', 'handlive' ); ?>
			<?php esc_html_e( 'Android is a trademark of Google LLC. Mac, iPhone, and iPad are trademarks of Apple Inc.', 'handlive' ); ?>
		</p>
	</div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
