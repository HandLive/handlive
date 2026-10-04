<?php
/**
 * Front page: the landing page is a regular page built in the block editor, one per language.
 * Its sections use full-width groups, so the template adds no container of its own.
 *
 * @package HandLive
 */

defined( 'ABSPATH' ) || exit;
get_header();
?>
<main id="main" class="hl-main hl-landing">
	<?php
	while ( have_posts() ) :
		the_post();
		the_content();
	endwhile;
	?>
</main>
<?php
get_footer();
