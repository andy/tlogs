(function(){
  
  try{
    // try to load local control class name
    var bmClassNameRegExp = new RegExp(" ?(" + bmLocalClassNameRegExp + "){1} ?", "i");
  } catch( e ){
    // load default control class name
    var bmClassNameRegExp = new RegExp(" ?(bm-reader){1} ?", "i");
  }
  
  var
    ua = navigator.userAgent,
    platform = navigator.platform || "",
    width = window.screen.availWidth || window.screen.width,
    height = window.screen.availHeight || window.screen.height,
    prefixes = {
      webkit: 'webkit',
      mozilla: 'moz',
      opera: 'o',
      ie: 'ms'
    }
  
  // correct win chrome bug
  if( ua.indexOf("Chrome") != -1 && platform.indexOf("Win") != -1 ){
    height -= 63;
    width -= 16;
  };
    
  var bmPopupParams = {
    "width"       : width,
    "height"      : height,
    "top"         : "0",
    "left"        : "0",
    "directories" : "no",
    "location"    : "no",
    "resizeable"  : "yes",
    "menubar"     : "no",
    "toolbar"     : "no",
    "scrollbars"  : "yes",
    "status"      : "no"
  };

  if( window.addEventListener )
    window.addEventListener( "load", bmOnLoad, false );

  else if( window.attachEvent )
    window.attachEvent( "onload", bmOnLoad );
    
  function bmOnLoad( event ){
    var nodes = document.getElementsByTagName("A");

    bmCreateIframe();

    for (var i=0; i < nodes.length; i++) {
      var nodeClass = nodes[i].className.match(bmClassNameRegExp),
          attrRel = nodes[i].getAttribute('rel'),
          attrTarget = nodes[i].getAttribute('target');

      if( attrRel == 'bookmate' ){
        if( attrTarget == '_blank' ){
          if( nodes[i].addEventListener )
            (function( node ){
              node.addEventListener( "click", function( event ){ bmOnClick.call( window, event, node ); }, false );
            })( nodes[i] );
          else if ( nodes[i].attachEvent )
            (function( node ){
              node.attachEvent( "onclick", function( event ){ bmOnClick.call( window, event, node ); } );
            })( nodes[i] );
        }
        
        else{
          if( nodes[i].addEventListener ){
            (function( node ){
              node.addEventListener( "click", function( event ){ bmOpenInIframe.call( window, event, node ); }, false );
            })( nodes[i] );
          }
          else if( nodes[i].attachEvent ){
            (function( node ){
              node.attachEvent( "onclick", function( event ){ bmOpenInIframe.call( window, event, node ); } );
            })( nodes[i] );
          }
        }
      }
    };
    
  };

  var getVieportWidth,
      getViewportHeight,
      getVerticalScroll,
      getDocumentWidth,
      getDocumentHeight;

  if (window.innerWidth) {
    // Все броузеры, кроме IE
    getViewportWidth = function() { return window.innerWidth; };
    getViewportHeight = function() { return window.innerHeight; };
    getVerticalScroll = function() { return window.pageYOffset; };
  }
  else if (document.documentElement && document.documentElement.clientWidth) {
    // Эти функции предназначены для IE 6 и документов с объявлением DOCTYPE
    getViewportWidth = function() { return document.documentElement.clientWidth; };
    getViewportHeight = function() { return document.documentElement.clientHeight; };
    getVerticalScroll = function() { return document.documentElement.scrollTop; };
  }
  else if (document.body.clientWidth) {
    // Эти функции предназначены для IE4, IE5 и IE6 без объявления DOCTYPE
    getViewportWidth = function() { return document.body.clientWidth; };
    getViewportHeight = function() { return document.body.clientHeight; };
    getVerticalScroll = function() { return document.body.scrollTop; };
  }

  if (document.documentElement && document.documentElement.scrollWidth) {
    getDocumentWidth = function() { return document.documentElement.scrollWidth; };
    getDocumentHeight = function() { return document.documentElement.scrollHeight; };
  }
  else if (document.body.scrollWidth) {
    getDocumentWidth = function() { return document.body.scrollWidth; };
    getDocumentHeight = function() { return document.body.scrollHeight; };
  }

  var isActive = false,
      isCSS3Support = false;

  function bmCreateIframe(){
    var iframe = document.getElementById('bookmateReader');

    if( !iframe ){
      var wrapperDiv = document.createElement('div'),
          shadowDiv = document.createElement('div'),
          iframeNode = document.createElement('iframe'),
          prefix;

      wrapperDiv.setAttribute('id', 'bmIframeWrapper');
      shadowDiv.setAttribute('id', 'boxShadow');
      iframeNode.setAttribute('id', 'bookmateReader');
      iframeNode.setAttribute('name', 'bookmateReaderIframe');

      wrapperDiv.appendChild( iframeNode );
      wrapperDiv.appendChild( shadowDiv );
      document.body.appendChild( wrapperDiv );

      wrapperDiv.style.cssText = 'display: none; background: rgba(0, 0, 0, 0.3); z-index:20; position: absolute; top: 0; left: 0; -webkit-transition: opacity 2s ease-in;';
      shadowDiv.style.cssText = 'border: 0; display: none; opacity: 0.2; background: #000; position: fixed; top: 45px; z-index: 1; filter:progid:DXImageTransform.Microsoft.Blur(pixelradius=2); -ms-filter:"progid:DXImageTransform.Microsoft.Blur(pixelradius=2)";';
      iframeNode.style.cssText = 'border: 0; background: #fff; position: fixed; top: 50px; z-index: 2;';
      
      for( var vendor in prefixes ){
        prefix = prefixes[ vendor ].charAt(0).toUpperCase() + prefixes[ vendor ].substr(1);
        
        if( !isCSS3Support && 'BoxShadow' in wrapperDiv.style || 'boxShadow' in wrapperDiv.style ){
          isCSS3Support = true;
          iframeNode.style.cssText += 'box-shadow: black 0em 0em 5em;';
        }
      
        else if( prefix + 'BoxShadow' in wrapperDiv.style ){
          isCSS3Support = true;
          iframeNode.style.cssText += '-' + prefix.toLowerCase() + '-box-shadow: black 0em 0em 5em;';
        }
      }

      if( !isCSS3Support ){
        shadowDiv.style.display = 'block';
      }

      bmCalcIframeSizes();

      if( wrapperDiv.addEventListener ){
        wrapperDiv.addEventListener('click', onWrapperClick, false);
      }
      else if( wrapperDiv.attachEvent ){
        wrapperDiv.attachEvent('onclick', onWrapperClick);
      }
    }
  }

  function onWrapperClick( event ){
    document.getElementById('bmIframeWrapper').style.display = 'none';
    isActive = false;
  }

  function bmOpenInIframe( event, node ){
    // prevent default action
    if( event.preventDefault ){
      event.preventDefault();
    }

    // prevent bubbling
    if( event.stopPropagation ){
      event.stopPropagation();
    }
      
    event.returnValue = false;
    event.cancelBubble = false;

    var iframe = document.getElementById('bookmateReader'),
        queryData = node.getAttribute('href').split('#')[1].split('&'),
        documentUUID;

    for( var i=0, l=queryData.length; i<l; i++ ){
      if( queryData[i].indexOf( 'd=' ) != -1 ){
        documentUUID = queryData[i].split('=')[1];
        break;
      }
    }

    if( iframe ){
      var iframeDocument = iframe.contentWindow || iframe.contentDocument; // Safari

      if( iframeDocument && iframeDocument.document ){
        iframeDocument = iframeDocument.document;
      }

      if( documentUUID ){
        iframe.parentNode.style.display = 'block';

        var host = 'www.bookmate.ru';
        iframeDocument.location = 'http://' + host + '/r#d=' + documentUUID + '&inline=true';
        isActive = true;
        iframe.focus();
      }
    }
  }
  
  function bmOnClick( event, node ){
    // prevent default action
    if( event.preventDefault )
      event.preventDefault();

    // prevent bubbling
    if( event.stopPropagation )
      event.stopPropagation();
      
    event.returnValue = false;
    event.cancelBubble = false;
    
    // find book href
    var href = node.getAttribute("href");

    // catch window name or generate own
    var windowName = node.getAttribute("target");
    if( !windowName )
      windowName = "BookmateReader" + (new Date()).getTime();
    
    // prepare params
    var params = "";
    for( key in bmPopupParams )
      params += key + "=" + bmPopupParams[key] + ",";

    params = params.replace(/,$/, "");
    
    // open popup;
    var popupWindow = window.open( href, windowName, params );
    popupWindow.focus();
  };

  function bmCalcIframeSizes(){
    var wrapperDiv = document.getElementById('bmIframeWrapper'),
        shadowDiv = document.getElementById('boxShadow'),
        iframeNode = document.getElementById('bookmateReader'),
        wrapperWidth = getViewportWidth(),
        iframeWidth = wrapperWidth - 100,
        iframeHeight = getViewportHeight() - 100;

    if( document.body.clientHeight && document.body.scrollHeight && document.body.clientHeight < document.body.scrollHeight ){
      wrapperWidth -= 15;
    }

    wrapperDiv.style.width = wrapperWidth + 'px';
    wrapperDiv.style.height = getDocumentHeight() + 'px';

    iframeNode.style.width = iframeWidth + 'px';
    iframeNode.style.height = iframeHeight + 'px';
    iframeNode.style.left = ( wrapperWidth / 2 - iframeWidth / 2 ) + 'px';

    shadowDiv.style.width = iframeWidth + 10 + 'px';
    shadowDiv.style.height = iframeHeight + 10 + 'px';
    shadowDiv.style.left = ( wrapperWidth / 2 - iframeWidth / 2 ) - 5 + 'px';

  }

  window.onresize = function(){
    bmCalcIframeSizes();

    if( isActive ){
      document.getElementById('bmIframeWrapper').style.display = 'block';
    }
  };

})();