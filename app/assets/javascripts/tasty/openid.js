var _login_mode = "email";
function login_openid_switcher ( value ) {
  if ( value.match ( /^(http|https)/ ) ) {
      if (_login_mode != "openid") {
        $('user_password').disabled = true;
        if ( $('user_password_label') ) {
          new Effect.Fade ( 'user_password_label', { duration: 0.5, from: 1.0, to: 0.2 } );
        }
        error_message_on('user_password', 'пароль не нужен, поскольку используется OpenID авторизация', true);
        _login_mode = "openid";
      }
  } else if (_login_mode != "email") {
    $('user_password').disabled = false;
    if ( $('user_password_label') ) {
      new Effect.Appear ( 'user_password_label', { duration: 0.5 } );
    }
    clear_error_message_on('user_password');
    _login_mode = "email";
  }
}
