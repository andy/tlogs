
$(document).bind "mobileinit", ->
  $.mobile.pageLoadErrorMessage = "Ошибка. Попробуйте позже."
  $.mobile.loadingMessage = null
  true

$ ->
  $('a[data-refresh-url]').live 'click', ->
    $.mobile.changePage $(this).data('refresh-url'), { reloadPage: true, transition: 'fade' }
