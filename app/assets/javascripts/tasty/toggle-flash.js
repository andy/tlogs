/* hide all flash object on page */
function toggle_flash(visibility) {
  var embeds = document.getElementsByTagName('embed');
  for(i = 0; i < embeds.length; i++) {
    embeds[i].style.visibility = visibility;
  }

  var objects = document.getElementsByTagName('object');
  for(i = 0; i < objects.length; i++) {
    objects[i].style.visibility = visibility;
  }
}

function hide_flash() {
  toggle_flash('hidden');
}

function show_flash() {
  toggle_flash('visible')
}