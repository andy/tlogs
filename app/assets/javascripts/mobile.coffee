
$(document).bind "mobileinit", ->
  $.mobile.pageLoadErrorMessage = "Ошибка. Попробуйте позже."
  $.mobile.loadingMessage = null
  true

$ ->
  $('a[data-refresh-url]').live 'click', ->
    $.mobile.changePage $(this).data('refresh-url'), { reloadPage: true, transition: 'fade' }

  # $('.t-form-login').live 'submit', (evt) ->
  #   console.log 'submit clicked'
  # 
  #   evt.preventDefault()
  # 
  #   false

  $('.t-act-logout').live 'click', ->
    $.ajax
      url: '/account/logout.json'
      type: 'post'
      data:
        authenticity_token:
          window._token
      success: (data) ->
        $.mobile.changePage '/', { reloadPage: true, transition: 'fade' }
        # window.location.reload()
    
    false