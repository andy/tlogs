/* google analytics page view tracking */
function ga_event(category, action, label, value) {
	if(pageTracker) {
		pageTracker._trackEvent(category, action, label, value);
	}
	return true;
}
