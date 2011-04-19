// Continuous Text Marquee
// copyright 30th September 2009by Stephen Chapman
// http://javascript.about.com
// permission to use this Javascript on your web page is granted
// provided that all of the code below in this script (including these
// comments) is used without any alteration
function objWidth(obj) {if(obj.offsetWidth) return  obj.offsetWidth; if (obj.clip) return obj.clip.width; return 0;} var mqr = []; function mq(id){this.mqo=document.getElementById(id); var wid = objWidth(this.mqo.getElementsByTagName('span')[0])+ 5; var fulwid = objWidth(this.mqo); var txt = this.mqo.getElementsByTagName('span')[0].innerHTML; this.mqo.innerHTML = ''; var heit = this.mqo.style.height; this.mqo.onmouseout=function() {mqRotate(mqr);}; this.mqo.onmouseover=function() {clearTimeout(mqr[0].TO);}; this.mqo.ary=[]; var maxw = Math.ceil(fulwid/wid)+1; for (var i=0;i < maxw;i++){this.mqo.ary[i]=document.createElement('div'); this.mqo.ary[i].innerHTML = txt; this.mqo.ary[i].style.position = 'absolute'; this.mqo.ary[i].style.left = (wid*i)+'px'; this.mqo.ary[i].style.width = wid+'px'; this.mqo.ary[i].style.height = heit; this.mqo.appendChild(this.mqo.ary[i]);} mqr.push(this.mqo);} function mqRotate(mqr){if (!mqr) return; for (var j=mqr.length - 1; j > -1; j--) {maxa = mqr[j].ary.length; for (var i=0;i<maxa;i++){var x = mqr[j].ary[i].style;  x.left=(parseInt(x.left,10)-1)+'px';} var y = mqr[j].ary[0].style; if (parseInt(y.left,10)+parseInt(y.width,10)<0) {var z = mqr[j].ary.shift(); z.style.left = (parseInt(z.style.left) + parseInt(z.style.width)*maxa) + 'px'; mqr[j].ary.push(z);}} mqr[0].TO=setTimeout('mqRotate(mqr)',20);}

// mousewheel event
function wheel(a){var b=0;if(!a)a=window.event;a.wheelDelta?(b=a.wheelDelta/120,window.opera&&(b=-b)):a.detail&&(b=-a.detail/3);b&&typeof handle=="function"&&handle(b);a.preventDefault&&a.preventDefault();a.returnValue=!1}window.addEventListener&&window.addEventListener("DOMMouseScroll",wheel,!1);window.onmousewheel=document.onmousewheel=wheel;
//

function getCookie(name) {
	var matches = document.cookie.match(new RegExp(
	  "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
	))
	return matches ? decodeURIComponent(matches[1]) : false 
}

function setCookie(name, value, props) {
	props = props || {}
	var exp = props.expires
	if (typeof exp == "number" && exp) {
		var d = new Date()
		d.setTime(d.getTime() + exp*1000)
		exp = props.expires = d
	}
	if(exp && exp.toUTCString) { props.expires = exp.toUTCString() }

	value = encodeURIComponent(value)
	var updatedCookie = name + "=" + value
	for(var propName in props){
		updatedCookie += "; " + propName
		var propValue = props[propName]
		if(propValue !== true){ updatedCookie += "=" + propValue }
	}
	document.cookie = updatedCookie

}

var tastyradio;
var songTimer;
function loadSong() {
	jQuery.ajax({
		url: '/tastyradio/data.json',
		data: {},
		success: function(json) {
			if (json.song != jQuery('#song_label_hidden').text()) {
				jQuery('.song_holder').html('<span class="song">'+json.song+'</span>');
				jQuery('#song_label_hidden').html(json.song).css('display', 'inline');
				var song_width = jQuery('#song_label_hidden').width();
				jQuery('#song_label_hidden').hide();
				var standartWidth = (jQuery('.big_player').length)?300:200;
				if (song_width > standartWidth) {
					if (mqr[0]) {
						clearTimeout(mqr[0].TO);
					}
					mqr = [];
					new mq('song');
					mqRotate(mqr);
				}
			}
			if(json.online > 0) {
				jQuery('.online span').text(json.online);
			} else {
				jQuery('.online span').text('неизвестно');
			}
		}
	});
	songTimer = setTimeout("loadSong()", 5000);
}

function getVolumePercent(volumePos, middle) {
	if (volumePos < 2)
		volumePos = 2;
	if (volumePos > 71)
		volumePos = 71;
	if ((volumePos > (69/2-5)) && (volumePos < (69/2+5)) && middle)
		volumePos = 74/2;
	
	setCookie('tr_v', volumePos, {expires: 60*60*24*30});
	jQuery('.knob').css('top', volumePos.toString()+'px');
	if (volumePos == 71) {
		jQuery('.up').attr('class', 'up_none');
		jQuery('.down').attr('class', 'mute');
	} else {
		jQuery('.up_none').attr('class', 'up');
		jQuery('.mute').attr('class', 'down');
	}
	
	var volumeRaw = 69 - (volumePos - 2);
	var volumePercent = volumeRaw*100/69;
	
	return volumePercent;
}

function setVolumeSlider(event) {
	var sliderTop = jQuery('.slider').offset().top;
	var volumePos = event.pageY - sliderTop;
	
	var volumePercent = getVolumePercent(volumePos, true);
	
	return volumePercent;
}

function volWheel(delta) {
	var volumePos = jQuery('.knob').position().top - 2;
	if (delta < 0) volumePos += 4;
	else volumePos -= 4;
	
	var volumePercent = getVolumePercent(volumePos, false);
	
	soundManager.setVolume('tastyradio', volumePercent);
}

var knobPressed = false;

function egychStart() {
	loadSong();

	jQuery('#play_stop').click(function(){
		if (jQuery(this).hasClass('play_btn')) {
			tastyradio.play();
			jQuery(this).attr('class', 'stop_btn');
		} else {
			tastyradio.pause();
			jQuery(this).attr('class', 'play_btn');
		}
	});

	jQuery('.knob').mousedown(function(event){
		knobPressed = true;
		event.preventDefault();
	});
	jQuery('.slider').mouseover(function(){
		handle = volWheel;
	});
	jQuery('.slider').mouseout(function(){
		handle = null;
	});
	jQuery('.knob').mouseup(function(){
		knobPressed = false;
	});
	jQuery(document).mousemove(function(event){
		if (knobPressed) {
			var vol = setVolumeSlider(event);
			soundManager.setVolume('tastyradio', vol);
		}
		return false;
	});
	jQuery(document).mouseup(function(){
		knobPressed = false;
	});
	jQuery('.up').click(function(){
		var sliderTop = jQuery('.slider').offset().top;
		var volMax = sliderTop + 2;
		var volumePos = volMax - sliderTop;
		setCookie('tr_v', volumePos, {expires: 60*60*24*30});
		jQuery('.knob').css('top', volumePos.toString()+'px');
		
		if (jQuery('.up_none').length)
			jQuery('.up_none').attr('class', 'up');
		if (jQuery('.mute').length)
			jQuery('.mute').attr('class', 'down');
		
		var volumeRaw = 69 - (volumePos - 2);
		var volumePercent = volumeRaw*100/69;
		
		soundManager.setVolume('tastyradio', volumePercent);
	});
	jQuery('.down').click(function(){
		var sliderTop = jQuery('.slider').offset().top;
		var volMax = sliderTop + 71;
		var volumePos = volMax - sliderTop;
		setCookie('tr_v', volumePos, {expires: 60*60*24*30});
		jQuery('.knob').css('top', volumePos.toString()+'px');
		
		if (jQuery('.up').length)
			jQuery('.up').attr('class', 'up_none');
		if (jQuery('.down').length)
			jQuery('.down').attr('class', 'mute');
	
		var volumeRaw = 69 - (volumePos - 2);
		var volumePercent = volumeRaw*100/69;
		
		soundManager.setVolume('tastyradio', volumePercent);
	});
	jQuery('.slider').mouseup(function(event){
		var vol = setVolumeSlider(event);
		soundManager.setVolume('tastyradio', vol);
		return false;
	});
	
	// ïðîáóåì áðàòü ãðîìêîñòü èç êóê
	var cookieVolume = getCookie('tr_v');
	var vol = 100;
	if (!cookieVolume) {
		var sliderTop = jQuery('.slider').offset().top;
		var volMax = sliderTop + 71;
		var volumePos = volMax - sliderTop;
		setCookie('tr_v', volumePos, {expires: 60*60*24*30});
	} else {
		jQuery('.knob').css('top', cookieVolume.toString()+'px');
		var volumeRaw = 69 - (cookieVolume - 2);
		vol = volumeRaw*100/69;
	}
	
	if (vol < 20) {
		vol = 20;
	}
	
	soundManager.url = '/swf/';
	soundManager.flashVersion = 9;
	soundManager.debugMode = false;
	soundManager.useFlashBlock = false;
	soundManager.onready(function() {
		tastyradio = soundManager.createSound({
			id: 'tastyradio',
			url: 'http://stream12.radiostyle.ru:8012/tastyradio',
			autoPlay: true,
			pan: -75,
			volume: vol
		});
	});	
}