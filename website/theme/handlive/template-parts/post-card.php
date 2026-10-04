<?php
/**
 * Post card in lists: cover, date, title, excerpt; the whole card is one link.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
?>
<article <?php post_class( 'hl-card hl-post-card' ); ?>>
	<?php if ( has_post_thumbnail() ) : ?>
		<div class="hl-post-card__cover"><?php the_post_thumbnail( 'medium_large', array( 'alt' => '' ) ); ?></div>
	<?php endif; ?>
	<div class="hl-post-card__body">
		<p class="hl-post-card__date"><time datetime="<?php echo esc_attr( get_the_date( 'c' ) ); ?>"><?php echo esc_html( handlive_date() ); ?></time></p>
		<h2 class="hl-post-card__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
		<p class="hl-post-card__excerpt"><?php echo esc_html( wp_strip_all_tags( get_the_excerpt() ) ); ?></p>
	</div>
</article>
