<?php
/**
 * Single page (Privacy and any other page).
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
				<h1 class="hl-article__title"><?php the_title(); ?></h1>
			</header>
			<div class="hl-prose"><?php the_content(); ?></div>
		</article>
	<?php endwhile; ?>
</main>
<?php
get_footer();
