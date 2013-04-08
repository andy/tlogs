jQuery(document).ready(function($){

	if ($.browser.msie && $.browser.version == '6.0') {
		$.getScript('style/js/DD_belatedPNG_0.0.8a-min.js');
		DD_belatedPNG.fix('.b-logotype img,.top .btm-sh-top,.b-company-logotype img,.b-main .b-image img,.b-reasons,.b-reasons-list .img img,.lighting-img,.button span,.button span span,.button .ico,.see-examples,.b-item .caption');
	}

	$('a[rel=to-anchor]').click(function(){
		var el = $(this).attr('href');
		if ($(el).length < 1) return false;
		$('body,html').animate({scrollTop:$(el).offset().top - 40}, 600);
		return false;
	})

})