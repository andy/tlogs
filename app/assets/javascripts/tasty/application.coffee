Tasty =
  ready: ->
    Tasty.fancybox.ready()
    
    jQuery('a.t-act-vote').live "click", Tasty.vote
    jQuery('a.t-act-fave').live "click", Tasty.fave
    jQuery('a.t-act-meta').live "click", Tasty.meta.click
    Tasty.fastforward.ready()
    jQuery('.t-act-logout').live "click", Tasty.logout
    jQuery('.t-controller-settings-social a.t-act-social-delete').live "click", Tasty.social.del
    jQuery('.t-controller-settings-social a.t-act-social-edit').live "click", Tasty.social.edit
    Tasty.shortcut.ready() if jQuery('#t-act-shortcut')
    Tasty.iscroll.ready() if jQuery('.t-iscrollable')

    true
    
  logout: (event) ->
    if confirm('Вы действительно хотите выйти?') == true
      form = jQuery('#t-logout-form')
      form.find("input[name='authenticity_token']").val(window._token)
      form.find("input[name='p']").val(window._is_private)
      form.submit()
    
    false
    
  analytics:
    hit: (url, title = null, referer = null) ->
      yaCounter5021200.hit(url, title, referer) if yaCounter5021200?
      
      true
      
    event: (category, action, label = null, value = null) ->
      if _gaq?
    	  _gaq.push(['_trackEvent', category, action, label, value])

      true

  iscroll:
    ready: (options = Tasty.iscroll.options) ->
      # set .next to what it should be
      Tasty.iscroll.next = jQuery('.t-iscrollable').data('iscroll-next')
      Tasty.iscroll.name = jQuery('.t-iscrollable').data('iscroll-name')
      if Tasty.iscroll.next
        jQuery.extend(options, { pathParse: Tasty.iscroll.parse })
      else
        jQuery.extend(options, { pathParse: Tasty.iscroll.path_save })
      
      jQuery('.t-iscrollable div.post_body').each (i, o) ->
        Tasty.iscroll.visible.push jQuery(o).attr('id')
        
      # load the stuff
      jQuery('.t-iscrollable').infinitescroll(options, Tasty.iscroll.handler)
    
    handler: (items) ->
      Tasty.iscroll.next = jQuery(items[items.length - 1]).data('entry-id')
      
      jQuery(items).each (i, o) ->
        item = jQuery(o)
        if item.attr('id') in Tasty.iscroll.visible
          item.hide()
        else
          Tasty.iscroll.visible.push item.attr('id')
      
      enable_services_for_current_user() if current_user
      
      Tasty.analytics.event('Infinite Scroll', Tasty.iscroll.name, current_site, Tasty.iscroll.iter)
      Tasty.analytics.hit(Tasty.iscroll.path, document.title)
      
      Tasty.fancybox.scoped(items)
    
    next: null
    
    name: null
    
    path: null
    
    visible: []

    options:
      infid: 1
      navSelector: '.entry_pagination'
      nextSelector: 'div.entry_pagination a.entry_paginate_prev'
      itemSelector: 'div.post_body'
      loadingImg: 'http://assets0.mmm-tasty.ru/images/blank.gif'
      loadingText: '<em>Загружаем ...</em>'
      donetext: '<em>К сожалению, на этом все.</em>'

    path_save: (path, iteration) ->
      Tasty.iscroll.iter = iteration
      Tasty.iscroll.path = path.match(/^(.*?)\b2\b(.*?$)/).slice(1).join(iteration)
      
      Tasty.iscroll.path
      
    parse: (path, iteration) ->
      Tasty.iscroll.iter = iteration
      Tasty.iscroll.path = path.match(/^(.*?)(\d+)$/)[1] + Tasty.iscroll.next
      
      Tasty.iscroll.path

  fancybox:
    ready: (options = Tasty.fancybox.options, popup_options = Tasty.fancybox.popup_options) ->
      Tasty.fancybox.scoped(document, options, popup_options)
    
    scoped: (scope, options = Tasty.fancybox.options, popup_options = Tasty.fancybox.popup_options) ->
      jQuery(scope).find('a.fancybox').removeClass('fancybox').fancybox(options)
      jQuery(scope).find('a.fancypopup').removeClass('fancypopup').fancybox(popup_options)
    
    popup_options:
      titleShow: false
      centerOnScroll: true
      autoDimensions: true
      hideOnOverlayClick : true
      hideOnContentClick: false
      onStart: ->
        Tasty.flash.hide()
        true
      onClosed: ->
        Tasty.flash.show()
        true      
      
    options:
      centerOnScroll: false
      hideOnContentClick: true
      showNavArrows: false
      enableKeyboardNav: false
      autoScale: false
      onStart: ->
        Tasty.flash.hide()
        true
      onClosed: ->
        Tasty.flash.show()
        true

  flash:
    hide: ->
      Tasty.flash.toggle 'hidden'
      
    show: ->
      Tasty.flash.toggle 'visible'
        
    toggle: (visibility) ->
      for tag in ['embed', 'object', 'iframe']
        jQuery("#{tag}:visible").css { visibility }

  social:
    del: (event) ->
      jQuery.ajax
        url: jQuery(this).data 'url'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        type: 'post'
        success: (data) =>
      
      new Effect.Highlight "relationship_#{jQuery(this).data('rel-id')}", { duration: 0.3 }
      new Effect.Fade "relationship_#{jQuery(this).data('rel-id')}", { duration: 0.3 }

      false
    
    edit: (event) ->
      jQuery.ajax
        url: jQuery(this).data 'url'
        dataType: 'script'
        data:
          authenticity_token:
            window._token
        type: 'get'

      false

  fastforward:
    ready: ->
      Tasty.fastforward.e = jQuery('a#t-act-fastforward')
      Tasty.fastforward.e.hover Tasty.fastforward.hoverIn, Tasty.fastforward.hoverOut
      Tasty.fastforward.e.live "click", Tasty.fastforward.click
      Tasty.fastforward.e.twipsy
        offset: 12
        placement: 'below'
        trigger: 'manual'
        html: true
        title: Tasty.fastforward.title
    
    e: null
    data: null
    fetched: false
    timeout: null
    
    title: ->
      if Tasty.fastforward.data
        "далее в перемотке: #{Tasty.fastforward.data.url} (+#{Tasty.fastforward.data.count})"
      else
        "на этом, похоже, всё"
    
    fetch: ->
      if Tasty.fastforward.fetched then Tasty.fastforward.data else Tasty.fastforward.load()
      
    load: ->
      jQuery.ajax
        url: Tasty.fastforward.e.data 'url'
        dataType: 'json'
        data:
          authenticity_token:
            window._token
        type: 'get'
        success: (data) =>
          Tasty.fastforward.fetched = true
          if data
            Tasty.fastforward.data = data
          else
            Tasty.fastforward.e.find('img').attr('src', '/images/fastforward_empty.gif')
    
    hoverIn: ->
      jQuery.when(Tasty.fastforward.fetch()).then ->
        clearTimeout(Tasty.fastforward.timeout) if Tasty.fastforward.timeout?
        Tasty.fastforward.timeout = setTimeout(Tasty.fastforward.show, 2000)
        
    hoverOut: ->
      clearTimeout(Tasty.fastforward.timeout) if Tasty.fastforward.timeout?
      Tasty.fastforward.hide()
    
    show: ->
      Tasty.fastforward.e.twipsy('show')

    hide: ->
      Tasty.fastforward.e.twipsy('hide')

    click: (event) ->
      Tasty.analytics.event 'Userbar', 'flash forward', _user.url

      jQuery.when(Tasty.fastforward.fetch()).then ->
        window.location.href = Tasty.fastforward.data.href if Tasty.fastforward.data?.href
        
      false      

  shortcut:
    ready: ->
      jQuery('#t-act-shortcut')
        .click(Tasty.shortcut.click)
        .hover(Tasty.shortcut.in, Tasty.shortcut.out)
      jQuery(window).scroll Tasty.shortcut.onscroll
      
      width     = jQuery('.sidebar:first').offset()?.left
      w_width   = jQuery('#wrapper').offset()?.left
      width     = w_width if width > w_width
      width     -= 20
      # disable shortcut for blackman
      width     = 10 if current_user && current_user == 46
      
      if width > 50
        jQuery('#t-act-shortcut').css { width, height: jQuery(window).height() }
      else
        jQuery('#t-act-shortcut').addClass 'thincut'
      
      Tasty.shortcut.onscroll()

    in: (event) ->
      if jQuery(this).hasClass('thincut')
        jQuery(this).css 'background-color': '#404040', 'color': 'white'
      else
        jQuery(this).css 'text-decoration': 'underline'      
    
    out: (event) ->
      if jQuery(this).hasClass('thincut')
        jQuery(this).css 'background-color': 'white', 'color': '#404040'
      else
        jQuery(this).css 'text-decoration': 'none'

    click: (event) ->
      Tasty.analytics.event 'Shortcut', 'Up'
      jQuery(window).scrollTop(0)
    
    onscroll: (event) ->
      shortcut  = jQuery('#t-act-shortcut')
      offset    = jQuery(window).scrollTop()
      if offset > 1024
        shortcut.fadeIn(100) unless shortcut.is(':visible')          
      else
        shortcut.fadeOut(100) if shortcut.is(':visible')
    
  vote: (event) ->
    Tasty.analytics.event 'Vote', jQuery(this).data('vote-action'), _user.url

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
    Tasty.analytics.event 'Fave', current_site, _user.url

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
        Tasty.flash.show()
      else
        meta.show(100).parent('.post_body').addClass('post_metadata_open').find('.t-act-meta').html('+')
        Tasty.flash.hide()

      true

jQuery ($) ->
  Tasty.ready()