/* google analytics page view tracking */
function ga_event(category, action, label, value) {
	if(ga_page_tracker) {
		ga_page_tracker._trackEvent(category, action, label, value);
	}
	return true;
}
