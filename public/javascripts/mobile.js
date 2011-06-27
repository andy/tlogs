/* mobile stuff goes here */

$(document).bind("mobileinit", function(){
  $.mobile.ajaxEnabled = true;
	$.mobile.pageLoadErrorMessage = 'Ошибка. Попробуйте позже.';
	$.mobile.loadingMessage = 'Загружаем';
});