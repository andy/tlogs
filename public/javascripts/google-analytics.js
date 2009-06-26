/* google analytics page view tracking */
function ga_page_view(path) {
	if(ga_page_tracker) {
		ga_page_tracker._trackPageview(path);
	}
	return true;
}
