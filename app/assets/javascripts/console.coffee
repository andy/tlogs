Console =
  ready: ->
    Console.user.ready()
    Console.invitations.ready()
    $('.c-act-none').live 'click', (event) ->
      false
  
  user:
    ready: ->
      $('.c-act-user-disable').live 'click', Console.user.disable
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
      
    
    disable: (event) ->
      $(this).addClass('disabled c-act-none').removeClass('c-act-user-disable')
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
      $(this).addClass('disabled c-act-none').removeClass('c-act-user-restore')
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