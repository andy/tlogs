var _errors_on = new Array;

/* Выставляем ошибку на элементе ... */
function error_message_on ( element, message, is_tip ) {
  var element = $(element);
  if ( !element )
    return;

  var element_error = $(element.id + '_error');
  var had_error = _errors_on.indexOf ( element.id ) != -1;

  if ( !element_error )
    return;

  if ( !had_error )
    _errors_on.push ( element.id );

  add_me = is_tip ? 'not_really_big_error' : 'error'
  remove_me = is_tip ? 'error' : 'not_really_big_error'
  element_error.removeClassName(remove_me);
  element_error.addClassName(add_me);
  
  is_tip ? element.removeClassName('input_error') : element.addClassName('input_error');
  is_tip ? element.addClassName('input_succeed') : element.removeClassName('input_succeed');

  Element.update ( element_error.id + '_content', message);
  Element.show ( element_error );
}

/* Удаляем ошибку с элемента */
function clear_error_message_on ( element ) {
  var element = $(element);
  var element_error = $(element.id + '_error');

  element.removeClassName('input_error');
  element.removeClassName('input_succeed');
  Element.update ( element_error.id + '_content', '');
  Element.hide ( element_error );
  _errors_on = _errors_on.without ( element.id );
}

/* Удаляем все ошибки */
function clear_all_errors ( ) {
  _errors_on.each ( function ( element ) { clear_error_message_on ( element ); } );
}
