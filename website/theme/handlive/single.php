<?php
/**
 * Blog post.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
get_header();
?>
<main id="main" class="hl-main">
	<?php
	while ( have_posts() ) :
		the_post();
		?>
		<article <?php post_class( 'hl-container hl-article' ); ?>>
			<header class="hl-article__header">
				<p class="hl-eyebrow"><a href="<?php echo esc_url( handlive_blog_url() ); ?>"><?php esc_html_e( 'Blog', 'handlive' ); ?></a></p>
				<h1 class="hl-article__title"><?php the_title(); ?></h1>
				<p class="hl-article__meta"><time datetime="<?php echo esc_attr( get_the_date( 'c' ) ); ?>"><?php echo esc_html( handlive_date() ); ?></time></p>
			</header>
			<?php if ( has_post_thumbnail() ) : ?>
				<figure class="hl-article__cover"><?php the_post_thumbnail( 'large', array( 'loading' => 'eager' ) ); ?></figure>
			<?php endif; ?>
			<div class="hl-prose"><?php the_content(); ?></div>
			<footer class="hl-article__footer">
				<a class="hl-back" href="<?php echo esc_url( handlive_blog_url() ); ?>"><?php esc_html_e( 'All posts', 'handlive' ); ?></a>
			</footer>
		</article>
	<?php endwhile; ?>
</main>
<?php
get_footer();
