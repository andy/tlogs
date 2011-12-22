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
      if current_user > 0
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
      Tasty.analytics.event 'Userbar', 'Fast Forward', _user.url

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
  
  radio:
    new_schedule: () ->
      jQuery('#new_radio_schedule').toggle()
      if !jQuery('#new_radio_schedule_block').hasClass('date_prepared')
        d = new Date()
        months = d.getMonth()
        jQuery('#radio_schedule_air_at_2i option[value="'+num+'"]').remove() for num in [1..months]
        days = d.getDate()-1
        jQuery('#radio_schedule_air_at_3i option[value="'+num+'"]').remove() for num in [1..days]
        jQuery('#new_radio_schedule_block').addClass('date_prepared')

      true
  
  mentions:
    options: 
      list: [],
      list_loaded: false,
      suggest: '',
      suggest_list: [],
      dog: -1,
      last_caret: 0,
      current_obj: false,
      escaped: false,
      scrollbar_size: -1,
      suggest_el_height: 22

    load: (selector, eid = false) ->
      if !Tasty.mentions.options.list_loaded && eid && selector.length
        jQuery('body').append('<div id="mentions_loader" class="t-mentions-holder" style="display:block;width:16px;height:16px;"><img src="/images/ajax-smaller-loader.gif" width="16" height="16" alt="загружаем список"/></div>')
        pos = Tasty.mentions.caret.get_xy(jQuery(selector))
        jQuery('#mentions_loader').css({ 'left': pos.x, 'top': pos.y })
        jQuery.ajax
          url: "/mentions/#{eid}"
          dataType: 'json'
          data:
            authenticity_token: 
              window._token
            entry_id:
              eid
          type: 'get'
          success: (data) =>
            jQuery('#mentions_loader').remove()
            if data.success
              Tasty.mentions.ready(data.list, selector, true)

        Tasty.mentions.options.list_loaded = true

      true

    ready: (l = '', selector = '', ajax = false) ->
      if l && selector
        if typeof l == 'string'
          l = jQuery.parseJSON(l)
        Tasty.mentions.options.list = l
        Tasty.mentions.options.list_loaded = true if !Tasty.mentions.options.list_loaded
        jQuery('body').append('<div id="mentions_holder" class="t-mentions-holder"><div class="box"><div id="mentions_scroll" class="antiscroll-inner"><div class="box-inner"><ul id="mentions_suggest"></ul></div></div></div></div>')
        Tasty.mentions.suggest.add_mention(value) for value in Tasty.mentions.options.list
        jQuery('#mentions_holder ul li').live "mouseover", Tasty.mentions.suggest.over
        jQuery('#mentions_holder ul li').live "click", Tasty.mentions.suggest.click
        Tasty.mentions.bind_events(selector)
        if ajax
          jQuery(selector).trigger('click')

      true

    bind_events: (selector = false) ->
      if selector
        jQuery(selector).live "keyup", Tasty.mentions.search
        jQuery(selector).live "click", Tasty.mentions.search
        jQuery(selector).bind "keydown", "tab", Tasty.mentions.complete
        jQuery(selector).bind "keydown", "return", Tasty.mentions.complete
        jQuery(selector).bind "keydown", "up", Tasty.mentions.suggest.controls
        jQuery(selector).bind "keydown", "down", Tasty.mentions.suggest.controls
        jQuery(selector).bind "keydown", "esc", Tasty.mentions.suggest.escape
        jQuery('*').bind      "click", Tasty.mentions.suggest.blur

      true

    complete: (s = false) ->
      if !s
        obj = this
      else
        if Tasty.mentions.options.current_obj
          obj = Tasty.mentions.options.current_obj

      if obj
        t = jQuery(obj).val()
        last_mention = Tasty.mentions.last_mention(obj)
        friend = ''
        if Tasty.mentions.options.suggest_list.length == 1
          friend = Tasty.mentions.options.suggest_list[0]
          friend = Tasty.mentions.options.suggest_list[0].url if typeof Tasty.mentions.options.suggest_list[0] != 'string'
        if Tasty.mentions.options.suggest_list.length > 1 && jQuery('#mentions_holder:visible').length
          if jQuery('#mentions_holder ul li.active').length
            friend = jQuery('#mentions_holder ul li.active').text()

        if friend.length
          c = t.substr(0, Tasty.mentions.options.dog+1)
          c += friend+' '

          m_length = 0
          if last_mention.length
            m_length = last_mention.length
          c += t.substr(Tasty.mentions.options.dog+1+m_length, t.length)
          jQuery(obj).val(c)
          Tasty.mentions.caret.set(obj, Tasty.mentions.options.dog+1+friend.length+1)
          Tasty.mentions.suggest.hide()
          Tasty.mentions.options.dog = -1
          Tasty.mentions.options.suggest_list = []
          return false

      true

    last_mention: (obj) ->
      t = jQuery(obj).val()
      last_dog = t.lastIndexOf('@', Tasty.mentions.caret.get(obj))
      last_word = /^[a-zA-Z0-9\-]+/.exec(t.substr(last_dog+1, Tasty.mentions.caret.get(obj)-last_dog))
      lw_index = t.indexOf(last_word, last_dog)
      if last_word
        last_word = last_word[0]
        if last_dog > -1 
          Tasty.mentions.options.dog = last_dog
        if last_dog > -1 && last_word.length && ((Tasty.mentions.caret.get(obj) >= lw_index) && (Tasty.mentions.caret.get(obj) <= lw_index+last_word.length-1))
          return last_word
      
      false

    search: (event) ->
      if Tasty.mentions.options.escaped
        Tasty.mentions.options.escaped = false
        return false
      if (event.keyCode == 40 || event.keyCode == 38 || event.keyCode == 13) && Tasty.mentions.options.dog > -1
        return false

      Tasty.mentions.suggest.hide()
      t = jQuery(this).val()
      if !/^[a-zA-Z0-9\-\@]$/.test(t.charAt(Tasty.mentions.caret.get(this))) && Tasty.mentions.options.dog > -1
        Tasty.mentions.options.dog = -1

        return false
      else
        if t.charAt(Tasty.mentions.caret.get(this)) == '@'
          Tasty.mentions.options.dog = Tasty.mentions.caret.get(this)
          Tasty.mentions.options.suggest = ''
        else
          suggest = Tasty.mentions.last_mention(this)
      
      if Tasty.mentions.options.dog > -1
        Tasty.mentions.options.suggest = ''
        Tasty.mentions.options.suggest = suggest.toLowerCase() if suggest
        if Tasty.mentions.options.suggest.length > 0
          Tasty.mentions.options.suggest_list = (value for value in Tasty.mentions.options.list when Tasty.mentions.compare value)
          if Tasty.mentions.options.suggest_list.length
            Tasty.mentions.suggest.show(this)
        else
          if Tasty.mentions.caret.get(this) == Tasty.mentions.options.dog
            Tasty.mentions.options.suggest_list = Tasty.mentions.options.list
            Tasty.mentions.suggest.show(this)
      
      false
    
    suggest:
      hide: ->
        Tasty.mentions.options.suggest_list = []
        jQuery('#mentions_holder').hide()

        true

      show: (obj) ->
        can_show = true
        if Tasty.mentions.options.suggest_list.length <= 1 && Tasty.mentions.last_mention(obj) == Tasty.mentions.options.suggest_list[0]
          can_show = false

        if can_show
          Tasty.mentions.options.current_obj = obj
          pos = Tasty.mentions.caret.get_xy(obj)
          jQuery('#mentions_holder').css('left', pos.x)
          jQuery('#mentions_holder').css('top', pos.y)
          jQuery('#mentions_holder').css('font-family', jQuery(obj).css('font-family'))
          jQuery('#mentions_holder ul li').hide()
          jQuery('#mentions_holder ul li#sm_'+value.url).show() for value in Tasty.mentions.options.suggest_list 
          jQuery('#mentions_holder').css('display', 'inline-block')
          jQuery('#mentions_scroll').scrollTop(0)
          jQuery('#mentions_holder .box').css('height', jQuery('#mentions_holder ul li:visible').length * (jQuery('#mentions_holder ul li:visible:first').height()+4))
          if jQuery('#mentions_holder').height() > 198
            jQuery('#mentions_holder .box').css('height', '198px')
            max_height = 198
            if jQuery('#mentions_holder').hasClass('antiscrolled')
              max_height = 198+Tasty.mentions.suggest.scrollbar_size()
            jQuery('#mentions_holder .box .antiscroll-inner').css('height', max_height)
          if !jQuery('#mentions_holder').hasClass('antiscrolled')
            jQuery('#mentions_holder .box').css('width', jQuery('#mentions_holder').width())
            jQuery('#mentions_holder').antiscroll()
            jQuery('#mentions_holder').addClass('antiscrolled')
          Tasty.mentions.options.last_caret = Tasty.mentions.caret.get(obj)+1
          jQuery('#mentions_holder ul li.active').removeClass('active') if jQuery('#mentions_holder ul li.active').length
          if Tasty.mentions.options.suggest_list.length == 1
            jQuery('#mentions_holder ul li:visible').addClass('active')

        false
      
      add_mention: (value) ->
        src = '/images/noavatar.gif'
        if value.pic
          src = value.pic
        jQuery('#mentions_holder ul').append('<li id="sm_'+value.url+'"><img src="'+src+'" alt="'+value.url+'" />'+value.url+'</li>')

        false

      controls: (event) ->
        if jQuery('#mentions_holder:visible').length && Tasty.mentions.options.suggest_list.length > 1
          jQuery('#mentions_holder').addClass('keydown')
          pos = jQuery('#mentions_scroll').scrollTop()
          if event.keyCode == 40 # down
            if !jQuery('#mentions_holder ul li.active').length
              jQuery('#mentions_holder ul li:visible:first').addClass('active')
            else
              if !jQuery('#mentions_holder ul li.active:visible:last-child').length
                index = jQuery('#mentions_holder ul li.active').index('#mentions_holder ul li:visible')
                if index < jQuery('#mentions_holder ul li:visible').length-1
                  jQuery('#mentions_holder ul li.active').removeClass('active')
                  jQuery('#mentions_holder ul li:visible:eq('+(index+1)+')').addClass('active')
                  pos += Tasty.mentions.options.suggest_el_height
          
          if event.keyCode == 38 # up
            if !jQuery('#mentions_holder ul li.active').length
              return false
            else 
              if !jQuery('#mentions_holder ul li.active:first-child:visible').length
                index = jQuery('#mentions_holder ul li.active').index('#mentions_holder ul li:visible')
                if index > 0
                  jQuery('#mentions_holder ul li.active').removeClass('active')
                  jQuery('#mentions_holder ul li:visible:eq('+(index-1)+')').addClass('active')
                  pos -= Tasty.mentions.options.suggest_el_height

          jQuery('#mentions_scroll').scrollTop(pos)
          return false

        true

      escape: ->
        if jQuery('#mentions_holder:visible').length
          jQuery(this).focus()
          Tasty.mentions.caret.set(this, Tasty.mentions.options.last_caret)
          Tasty.mentions.suggest.hide()
          Tasty.mentions.options.escaped = true
          return false
        
        true

      over: ->
        if !jQuery('#mentions_holder').hasClass('keydown')
          jQuery('#mentions_holder ul li.active').removeClass('active') if jQuery('#mentions_holder ul li.active').length
          jQuery(this).addClass('active')
        else
          jQuery('#mentions_holder').removeClass('keydown')

        true

      click: ->
        Tasty.mentions.complete(true)

        false

      blur: (e) ->
        if !jQuery(e.target).parents().is('#mentions_holder')
          Tasty.mentions.suggest.hide()
        else
          jQuery(Tasty.mentions.options.current_obj).focus()

        true
      
      scrollbar_size: ->
        if Tasty.mentions.options.scrollbar_size == -1
          div = jQuery('<div style="width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;"><div style="height:100px;"></div>')
          jQuery('body').append(div)
          w1 = jQuery('div', div).innerWidth()
          div.css('overflow-y', 'scroll')
          w2 = jQuery('div', div).innerWidth()
          jQuery(div).remove()
          Tasty.mentions.options.scrollbar_size = w1 - w2

        Tasty.mentions.options.scrollbar_size

    compare: (value) ->
      value = value.url if typeof value != 'string'
      item = value.toLowerCase()
      index = item.indexOf(Tasty.mentions.options.suggest)
      if index == 0 || item[index-1] == '-'
        return true

      false 

    caret: 
      set: (obj, pos) ->
        if typeof(obj.caretPos) != 'undefined'
          obj.caretPos = pos
        else
          if obj.selectionEnd
            obj.selectionEnd = pos

        false

      get: (obj) ->
        selection = 0
        if obj.selectionStart 
          selection = obj.selectionStart
        
        if document.selection
          sel = document.selection.createRange()
          clone = sel.duplicate()
          sel.collapse(true)
          clone.moveToElementText(obj)
          clone.setEndPoint('EndToEnd', sel)
          selection clone.text.length;

        return selection-1

      get_xy: (obj) ->
        pos = { 'x':0, 'y':0 }
        if (jQuery(obj).is('textarea') || jQuery(obj).is('input')) && obj.selectionEnd != null
          c = [
            "height",
            "width",
            "padding-top",
            "padding-right",
            "padding-bottom",
            "padding-left",
            "lineHeight",
            "textDecoration",
            "letterSpacing",
            "font-family",
            "font-size",
            "font-style",
            "font-variant",
            "font-weight"
          ]
          h = {
            position:"absolute",
            overflow:"auto",
            "white-space":"pre-wrap",
            top:0,
            left:-9999
          }
          h[item] = jQuery(obj).css(c[i]) for item,i in c
          d=document.createElement("div")
          jQuery(d).css(h)
          jQuery(obj).after(d)
          if obj.value
            sstr = obj.value.substring(0, obj.selectionEnd)
          else
            sstr = '@'
          d.textContent = sstr
          d.scrollTop = d.scrollHeight
          e = document.createElement("span")
          e.innerHTML = "&nbsp;"
          d.appendChild(e)
          g = jQuery(e).position()
          jQuery(d).remove()
          pos = { 'x':g.left, 'y':g.top }

        left = jQuery(obj).offset().left+(parseInt(jQuery(obj).css('font-size'))/2)
        top = jQuery(obj).offset().top+parseInt(jQuery(obj).css('font-size'))+7

        return { 'x':left+pos.x-3, 'y':top+pos.y }

jQuery ($) ->
  Tasty.ready()