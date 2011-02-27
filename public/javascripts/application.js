// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function remote_request_started(button_element, text) {
  var button_element = $(button_element);
  button_element.value = text;
  button_element.disable();
}

function remote_request_finished(button_element, text) {
  var button_element = $(button_element);
  button_element.value = text;
  button_element.enable();
}

function sidebar_toggle(section) {
  var prefix = 'sidebar_' + section
  Effect.toggle(prefix + '_content', 'blind', { duration: 0.3 });
  Element.toggleClassName(prefix + '_link', 'highlight');
  ga_event("Sidebar", section);
  return false;
}

/* меняет количество комментариев на странице */
function run_comments_views_update( ) {
  if (typeof comments_views_update == 'undefined')
    return;

  comments_views_update.each( function(object) {
    // var attr = object.attributes;
    var text = object.comments_count;

    if (object.last_comment_viewed > 0 && object.last_comment_viewed != object.comments_count) {
      text = object.last_comment_viewed + '+' + (object.comments_count - object.last_comment_viewed);
    } else if (current_user > 0 && !object.last_comment_viewed && object.comments_count > 0 ) {
      text = '+' + object.comments_count
    }
    var element = $('entry_comments_count_' + object.id);
    if (element)
      Element.update(element, text);
  });
}

/* обновляем количество голосов за показываемые записи */
function run_entry_ratings_update( ) {
  if (typeof entry_ratings_update == 'undefined')
    return;
    
  entry_ratings_update.each ( function(object) {
    var element = $('entry_rating_' + object.id);
    if (element) Element.update(element, object.value);
  });
}

/* показываем штуки которые имеет смысл показывать только в том случае, если у нас есть какой-то залогиненный пользователь */
function enable_services_for_current_user( ) {
  /* все ссылки котоыре можно показывать текущему пользователю */
  $$(".enable_for_current_user").each( function(element) { element.show(); });

  /* показываем все элементы для которых _текущий_ пользователь является владельцем */
  $$(".enable_for_owner_" + current_user).each( function(element) { element.show(); });
  /* в обратную сторону - прячем все */
  $$(".disable_for_owner_" + current_user).each( function(element) { element.hide(); });

  /* прячем его собственные записи - все равно он за них не сможет голосовать */
  $$(".service_rating_owner_" + current_user).each( function(holder) {
    $$(".entry_voter", holder.id).each( function(element) { element.hide(); });
  });

}

document.observe('dom:loaded', function( ) { 
  run_comments_views_update();
  run_entry_ratings_update();
  if(current_user)
    enable_services_for_current_user();
});


function emulate_rails_flash(klass, message) {
	// remove element if exists
	if(jQuery('#flash_holder').length != 0) { jQuery('#flash_holder').remove(); }
	
	// create new one
	jQuery('.onair').prepend("<div id='flash_holder'><table id='flash'><tr><td id='flash_message'><p></p></td></tr></table></div>");
	jQuery('#flash').click(function() { jQuery(this).fadeOut(300, function() { jQuery('#flash_holder').remove(); }); });
	jQuery('#flash_holder #flash_message').addClass(klass).find('p').text(message);
}

var reply_to_comments = new Array;
var reply_to_string = null;

function _update_comment_textarea( ) {
  comment = $('comment_comment');

  if(reply_to_comments.length > 0) {
    reply_to_string = '<b>' + reply_to_comments.map( function(id) { return $('comment_author_'+id).innerHTML; } ).join(', ') + ':</b>';
    if (comment.value.match(/^<b>.*:<\/b>/)) {
      comment.value = comment.value.replace(/^<b>.*:<\/b>/i, reply_to_string);
    } else {
      comment.value = reply_to_string + ' ' + comment.value;
    }
  } else if (comment.value.match(/^<b>.*:<\/b>/)) {
    comment.value = comment.value.replace(/^<b>.*:<\/b>/i, '');
  }
}

function reply_to_comment(id) {
  Element.show('replying_to_comment_' + id);
  Element.hide('reply_to_comment_' + id);
  if(reply_to_comments.indexOf(id) == -1) reply_to_comments.push(id);
  $('comment_reply_to').value = reply_to_comments.join(',');
  _update_comment_textarea();
}

function do_not_reply_to_comment(id) {
  Element.hide('replying_to_comment_' + id);
  Element.show('reply_to_comment_' + id);
  if(reply_to_comments.indexOf(id) != -1) reply_to_comments = reply_to_comments.without(id);
  $('comment_reply_to').value = reply_to_comments.join(',');  
  _update_comment_textarea();
}

/* ie hover fix */
function makeHover(classList) {
  classList.each(function(item) {
    if ($$('.' + item).length) {
      $$('.' + item).each(function(node) {
        node.onmouseover=function() { this.className+=" hover"; }
        node.onmouseout=function() { this.className=this.className.replace (" hover", ""); }
      });
    }
  });
}

if(/MSIE/.test(navigator.userAgent) && !window.opera) {
  document.observe('dom:loaded', function() {
    var classes = new Array('post_body');
    makeHover(classes);
  });
}

jQuery(document).ready(function() {
	jQuery('a.fancybox').each( function(i, obj) { jQuery(obj).fancybox({ centerOnScroll: true, hideOnContentClick: true }); } );
});