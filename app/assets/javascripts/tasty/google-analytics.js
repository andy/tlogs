/* google analytics page view tracking */
function ga_event(category, action, label, value) {
  if(typeof _gaq != 'undefined') {
    _gaq.push(['_trackEvent', category, action, label, value]);
  }
  if (typeof mixpanel !== "undefined" && mixpanel !== null) {
    mixpanel.track([category, action, label, value].join(' '));
  }
  return true;
}
