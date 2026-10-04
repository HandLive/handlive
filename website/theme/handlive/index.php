<?php
/**
 * Post lists: the blog index, archives and search results (WordPress falls back to this template).
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
get_header();

if ( is_home() ) {
	$heading = __( 'Blog', 'handlive' );
	$intro   = __( 'News, releases, and notes from the people building HandLive.', 'handlive' );
} elseif ( is_search() ) {
	/* translators: %s: search terms. */
	$heading = sprintf( __( 'Results for “%s”', 'handlive' ), get_search_query() );
	$intro   = '';
} else {
	$heading = wp_strip_all_tags( get_the_archive_title() );
	$intro   = wp_strip_all_tags( get_the_archive_description() );
}
?>
<main id="main" class="hl-main">
	<div class="hl-container">
		<header class="hl-list__header">
			<h1 class="hl-list__title"><?php echo esc_html( $heading ); ?></h1>
			<?php if ( $intro ) : ?>
				<p class="hl-lead"><?php echo esc_html( $intro ); ?></p>
			<?php endif; ?>
		</header>
		<?php if ( have_posts() ) : ?>
			<div class="hl-cards">
				<?php
				while ( have_posts() ) :
					the_post();
					get_template_part( 'template-parts/post-card' );
				endwhile;
				?>
			</div>
			<?php
			the_posts_pagination(
				array(
					'prev_text' => __( 'Newer posts', 'handlive' ),
					'next_text' => __( 'Older posts', 'handlive' ),
				)
			);
			?>
		<?php else : ?>
			<p class="hl-empty"><?php esc_html_e( 'No posts yet.', 'handlive' ); ?></p>
		<?php endif; ?>
	</div>
</main>
<?php
get_footer();
