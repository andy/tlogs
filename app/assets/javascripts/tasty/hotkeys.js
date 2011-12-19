/* our hotkeys */

jQuery(document).ready(function($){
  /* Comment submit with ctrl+return */
  $('textarea#comment_comment').bind('keydown', 'Ctrl+return', function(evt) {
    $(this).closest('form').find("#comment_submit_button").trigger('click');
    return false;
  });
  $('textarea#comment_comment').bind('keydown', 'Shift+@', function(evt) {
  	if (jQuery('.post_body').length) {
    	return Tasty.mentions.load('textarea#comment_comment', jQuery('.post_body').data('entry-id'));
    }
    return true;
  });
});