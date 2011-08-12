Tasty =
  ready: ->
    jQuery('a.t-act-vote').live "click", Tasty.vote
    jQuery('a.t-act-fave').live "click", Tasty.fave
    jQuery('a.t-act-meta').live "click", Tasty.meta.click
    Tasty.shortcut.ready() if jQuery('#t-act-shortcut')
    true

  shortcut:
    ready: ->
      jQuery('#t-act-shortcut')
        .click(Tasty.shortcut.click)
        .hover(Tasty.shortcut.in, Tasty.shortcut.out)
      jQuery(window).scroll Tasty.shortcut.onscroll
      
      width   = jQuery('#wrapper').offset()?.left || 40
      height  = jQuery(window).height() || 400

      jQuery('#t-act-shortcut').css { width, height }
      
      Tasty.shortcut.onscroll()

    in: (event) ->
      jQuery('#t-act-shortcut').css 'text-decoration': 'underline'
    
    out: (event) ->
      jQuery('#t-act-shortcut').css 'text-decoration': 'none'

    click: (event) ->
      jQuery('body').scrollTop(0)
    
    onscroll: (event) ->
      shortcut  = jQuery('#t-act-shortcut')
      offset    = jQuery('body').scrollTop()
      if offset > 1024
        shortcut.fadeIn(100) unless shortcut.is(':visible')          
      else
        shortcut.fadeOut(100) if shortcut.is(':visible')
    
  vote: (event) ->
    jQuery.ajax
      url: "/vote/#{jQuery(this).data('vote-id')}/#{jQuery(this).data('vote-action')}"
      dataType: 'json'
      data:
        authenticity_token:
          window._token
      type: 'post'
      success: (data) =>
        jQuery(this).parentsUntil('.post_body').find('.service_rating .entry_rating').text(data)
    false
    
  fave: (event) ->
    jQuery.ajax
      url: "/global/fave/#{jQuery(this).data('entry-id')}"
      dataType: 'json'
      data:
        authenticity_token:
          window._token
      type: 'post'
      success: (data) =>
        new Effect.Highlight jQuery(this).attr('id')
    false

  meta:
    click: (event) ->
      entry_id = jQuery(this).data('entry-id')
      if jQuery(this).data 'fetched'
        Tasty.meta.toggle entry_id 
      else
        return false if jQuery(this).data('fetching')

        jQuery(this).data 'fetching', true
        jQuery.ajax
          url: jQuery(this).data 'url'
          dataType: 'html'
          data:
            authenticity_token:
              window._token
          type: 'get'
          success: (data) =>
            jQuery(this).data 'fetched', true
            jQuery("#emd_#{entry_id}").html(data).find('form').live 'submit', ->
              jQuery(this).find('input[type="button"]').click()
              false            
            Tasty.meta.toggle entry_id
      false

    toggle: (entry_id) ->
      meta = jQuery "#emd_#{entry_id}"
      if meta.is(':visible')
        meta.hide(100).parent('.post_body').removeClass('post_metadata_open').find('.t-act-meta').html('&ndash;')
        show_flash
      else
        meta.show(100).parent('.post_body').addClass('post_metadata_open').find('.t-act-meta').html('+')
        hide_flash      


jQuery ($) ->
  Tasty.ready()