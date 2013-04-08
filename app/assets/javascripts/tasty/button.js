var Button = {
  // initalize all buttons
  init: function() {
    Button.enable('input.button');
    Button.disable('input.button:disabled');
  },

  // enable button
  enable: function(expression) {
    jQuery(expression).removeAttr("disabled").removeClass('disabled');
  },

  // disable button
  disable: function(expression) {
    jQuery(expression).attr("disabled", "disabled").addClass('disabled');
  }
}

jQuery(document).ready(function($) {
  Button.init();
});
