/* our hotkeys */

jQuery(document).ready(function($){
  /* Comment submit with ctrl+return */
  $('textarea#comment_comment').bind('keydown', 'Ctrl+return', function(evt) {
    $(this).closest('form').find("#comment_submit_button").trigger('click');
    return false;
  });
});