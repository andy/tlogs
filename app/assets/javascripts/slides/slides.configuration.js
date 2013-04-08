(function($){
  $.extend($.fn.slides.option, {
    preload: true, // boolean, Set true to preload images in an image based slideshow
    preloadImage: '/images/slides/loading.gif', // string, Name and location of loading image for preloader. Default is "/img/loading.gif"
    container: 't-slides-container', // string, Class name for slides container. Default is "slides_container"
    generateNextPrev: false, // boolean, Auto generate next/prev buttons
    next: 't-slide-next', // string, Class name for next button
    prev: 't-slide-prev', // string, Class name for previous button
    pagination: true, // boolean, If you're not using pagination you can set to false, but don't have to
    generatePagination: true, // boolean, Auto generate pagination
    prependPagination: false, // boolean, prepend pagination
    paginationClass: 't-slides-pagination', // string, Class name for pagination
    currentClass: 't-slide-current', // string, Class name for current class
    autoHeight: true, // boolean, Set to true to auto adjust height
    autoHeightSpeed: 350, // number, Set auto height animation time in milliseconds
    bigTarget: false, // boolean, Set to true and the whole slide will link to next slide on click
  });
})(jQuery);
