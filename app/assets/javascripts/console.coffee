Console =
  ready: ->
    Console.user.ready()
    Console.invitations.ready()
    $('.c-act-none').live 'click', (event) ->
      false
    $('.line').peity 'bar'
      width: 128
  
  user:
    ready: ->
      $('.c-act-user-wipeout').live 'click', Console.user.wipeout
      $('.c-act-user-disable').live 'click', Console.user.disable
      $('.c-act-user-destroy').live 'click', Console.user.destroy
      $('.c-act-user-restore').live 'click', Console.user.restore
      $('.c-act-user-mprevoke').live 'click', Console.user.mprevoke
      $('.c-act-user-mpgrant').live 'click', Console.user.mpgrant
    
    mprevoke: (event) ->
      $(this).parent().html('<span class="label label-info">done</span>')

      $.ajax
        url: "/console/users/#{$(this).data('id')}/mprevoke"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
      false
    
    mpgrant: (event) ->
      $(this).parent().html('<span class="label label-info">done</span>')

      $.ajax
        url: "/console/users/#{$(this).data('id')}/mpgrant"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
      false

    wipeout: (event) ->
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/wipeout"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        success: (data) ->
          window.location.reload()

      false

    destroy: (event) ->
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/destroy"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        success: (data) ->
          window.location.reload()
      
      false
      
    
    disable: (event) ->
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/disable"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        success: (data) ->
          window.location.reload()
      
      false
    
    restore: (event) ->
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/restore"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        success: (data) ->
          window.location.reload()
      
      false
      
  
  invitations:
    ready: ->
      $('.c-act-invitations-inc').live 'click', Console.invitations.inc
      $('.c-act-invitations-dec').live 'click', Console.invitations.dec

    send: (id, value) ->
      $.ajax
        url: "/console/users/#{id}/invitations"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token: window._token
          inc: value
        success: (data) ->
          counter = $('#c-invitations-cnt')
          counter.html(data)
          if data > 0
            counter.addClass('badge-success')
          else
            counter.removeClass('badge-success')

      false
    
    dec: (event) ->
      Console.invitations.send $(this).data('id'), false
    
    inc: (event) ->
      Console.invitations.send $(this).data('id'), true

jQuery ($) ->
  Console.ready()