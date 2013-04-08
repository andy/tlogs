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
    if (element) {
      Element.update(element, text);

			if(object.comments_count > 0) {
				/* add .has_comments class to two parent divs (this will make bubble visible) */
				var elm_p = element.up('div.comment_cloud');
				if(elm_p && !elm_p.hasClassName('has_comments')) {
					elm_p.addClassName('has_comments');
				}
			
				var elm_p = elm_p.up('div.service_comments');
				if(elm_p && !elm_p.hasClassName('has_comments')) {
					elm_p.addClassName('has_comments');
				}
			} else {
				/* remove .has_comments class to two parent divs (this will make bubble invisible) */
				var elm_p = element.up('div.comment_cloud');
				if(elm_p && elm_p.hasClassName('has_comments')) {
					elm_p.removeClassName('has_comments');
				}
			
				var elm_p = elm_p.up('div.service_comments');
				if(elm_p && elm_p.hasClassName('has_comments')) {
					elm_p.removeClassName('has_comments');
				}
			}
		}
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

/*
 * enable and disable links depending on which user is currently looking at
 * the page
 *
 * purpose of that is to make pages as cacheable as possible and let js code
 * do the dynamic tweaking and tuning
 */
function enable_services_for_current_user( ) {
	/*
	 * Note here: we can't really use .show() method here, as it will set default element
	 * display setting, rather than let the browser decide
	 */

  /* all links that can be shown to logged in user */
  jQuery(".enable_for_current_user").css('display', '');

  /* enable elements that current user is owner of */
  jQuery(".enable_for_owner_" + current_user).css('display', '');

  /* disable elements that must be disabled for this current user */
  jQuery(".disable_for_owner_" + current_user).hide();

  /* disable voting for his entries (he wont be able to do that, anyway) */
  jQuery(".service_rating_owner_" + current_user + " .entry_voter").hide();
}

document.observe('dom:loaded', function( ) {
  /* make sure we run within tasty app stack */
  if(typeof current_user != 'undefined') {
    run_comments_views_update();
    run_entry_ratings_update();
  	jQuery('input, textarea').placeholder();
    if(current_user) {
      enable_services_for_current_user();
    }
  }
});


function emulate_rails_flash(klass, message) {
	// remove element if exists
	if(jQuery('#flash_holder').length != 0) { jQuery('#flash_holder').remove(); }
	
	// create new one
	jQuery('.onair').prepend("<div id='flash_holder'><table id='flash'><tr><td id='flash_message'><p></p></td></tr></table></div>");
	jQuery('#flash').click(function() { jQuery(this).fadeOut(300, function() { jQuery('#flash_holder').remove(); }); });
	jQuery('#flash_holder #flash_message').addClass(klass).find('p').text(message);
}

jQuery(document).ready(function() {	
	jQuery('a, button').focus(function(){ this.blur();} );

	jQuery('#pref_friends_holder .pref_friends_user').live('click', function() {
	  ga_event('Userbar', 'Heart', jQuery(this).find('a').val());
	  return true;
	});

	jQuery('#invoke-pref-fav').click(function() {
    if(jQuery(this).data('fetched')) {
      var img = jQuery(this).find('img');
      if(jQuery('#pref_friends_holder').is(':visible')) {
        jQuery('#pref_friends_holder').hide();
        img.attr('src', img.data('inactive'));
      } else {
        jQuery('#pref_friends_holder').show();
        img.attr('src', img.data('active'));        
      }        
    } else {
      if(jQuery(this).data('fetching')) {
        // prevent double clicks
      } else {
        jQuery(this).data('fetching', true);
        jQuery.ajax({
          url: jQuery(this).data('url'),
          success: function(content) {
            jQuery(content).each(function() {
              tmpl = '<div class="pref_friends_user pref_friendship_status_' + this['fs'] + '">'
              tmpl += '<a href="' + this['href'] + '" class="pref_link_tlog">' + this['url'] + '</a>'
              tmpl += '&nbsp;<span class="pref_new_entry" title="количество новых записей">'
              if(this['count'] > 0) {
                tmpl += '+' + this['count']
              }
              tmpl += '</span></div>'

              jQuery('.pref_friends_control').before(tmpl);
            });
            jQuery('#invoke-pref-fav').data('fetched', true);

            var img = jQuery('#invoke-pref-fav img')
            img.attr('src', img.data('active'));

            jQuery('#pref_friends_holder').show();
          },
          dataType: 'json',
          type: 'post',
          data: { authenticity_token: window._token }
        });
        
      }
    }

    return false;
	});
});