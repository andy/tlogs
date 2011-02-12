/* google analytics page view tracking */
function ga_event(category, action, label, value) {
	if(typeof _gaq != 'undefined') {
		_gaq.push(['_trackEvent', category, action, label, value]);
	}
	
	// console.log('goog track event, c=' + category + ' ' + ' a=' + action + ' l=' + label + ' v=' + value);
	return true;
}
