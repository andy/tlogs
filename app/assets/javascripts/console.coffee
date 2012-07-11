Console =
  ready: ->
    Console.user.ready()
    Console.invitations.ready()
    $(document).bind 'keydown', 'Ctrl+/', (event) ->
      $('#console-search').focus()
      false

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
      $('.c-act-user-confirm').live 'click', Console.user.confirm
      $('.c-act-ac-change').live 'click', Console.user.acchange
      $('#ac-change-duration').change (event) ->
        val = $(this).val()
        if val > 0
          $('#ac-change-duration-value').addClass('badge-important').removeClass('badge-success')
          $('.c-act-ac-change').addClass('btn-danger').removeClass('btn-success').html('<i class="icon-ban-circle icon-white"></i> Установить')
        else
          $('#ac-change-duration-value').addClass('badge-success').removeClass('badge-important')
          $('.c-act-ac-change').addClass('btn-success').removeClass('btn-danger').html('<i class="icon-ban-circle icon-white"></i> Снять бан')
        
        $('#ac-change-duration-value').html $(this).val()
    
    acchange: (event) ->
      $(this).button('loading')

      $.ajax
        url: "/console/users/#{$(this).data('id')}/acchange"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          duration: $('#ac-change-duration').val()
        success: (data) ->
          window.location.reload()

      false
      
      
    confirm: (event) ->
      password = $('#confirm-password')
      if password.val() == '' || password.val().length < 6
        password.closest('.control-group').addClass('error')
        password.closest('.modal-body').find('.alert').toggle('show')
        return false
      
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/confirm"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          password: password.val()
        success: (data) ->
          window.location.reload()

      false
      
    mprevoke: (event) ->
      comment = $('#mprevoke-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false

      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/mprevoke"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()
        success: (data) ->
          window.location.reload()

      false
    
    mpgrant: (event) ->
      comment = $('#mpgrant-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false

      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/mpgrant"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()
        success: (data) ->
          window.location.reload()

      false

    wipeout: (event) ->
      comment = $('#wipeout-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false
      
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/wipeout"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()
        success: (data) ->
          window.location.reload()

      false

    destroy: (event) ->
      comment = $('#destroyAccount-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false

      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/destroy"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()
        success: (data) ->
          window.location.reload()
      
      false
      
    
    disable: (event) ->
      comment = $('#disableAccount-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false
      
      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/disable"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()

        success: (data) ->
          window.location.reload()
      
      false
    
    restore: (event) ->
      comment = $('#restore-comment')
      if comment.val() == ''
        comment.closest('.control-group').addClass('error')
        comment.closest('.modal-body').find('.alert').toggle('show')
        return false

      $(this).button('loading')
      $.ajax
        url: "/console/users/#{$(this).data('id')}/restore"
        type: 'post'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
          comment: comment.val()
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