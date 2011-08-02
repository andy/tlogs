// fixPNG(); http://www.tigir.com/js/fixpng.js (author Tigirlas Igor)
function fixPNG(element) {
	if (/MSIE (5\.5|6).+Win/.test(navigator.userAgent))
	{
		var src;
		
		if (element.tagName=='IMG')
		{
			if (/\.png(\?[0-9]+)?$/.test(element.src))
			{
				src = element.src;
				element.src = "http://www.mmm-tasty.ru/images/blank.gif";
			}
		}
		else
		{
			src = element.currentStyle.backgroundImage.match(/url\("(.+\.png(\?[0-9]+)?)"\)/i)
			if (src)
			{
				src = src[1];
				element.runtimeStyle.backgroundImage="none";
			}
		}
		
		if (src) element.runtimeStyle.filter = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + src + "',sizingMethod='scale')";
	}
}
