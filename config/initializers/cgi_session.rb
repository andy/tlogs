CGI::Session.expire_after 3.months
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:session_domain => '.mmm-tasty.ru')