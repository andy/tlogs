tlog_settings = lambda do |tlog|
  tlog.tlog '', :action => 'index'
  tlog.page 'page/:page', :action => 'index', :page => /\d+/

  tlog.publish 'publish/:action/:id', :controller => 'publish'
  tlog.settings_social 'settings/social/:action', :controller => 'settings/social'
  tlog.settings_sidebar 'settings/sidebar/:action/:id', :controller => 'settings/sidebar'
  tlog.settings_mobile 'settings/mobile/:action/:id', :controller => 'settings/mobile'
  tlog.settings_premium 'settings/premium/:action', :controller => 'settings/premium'
  tlog.settings 'settings/:action', :controller => 'settings/default'
  tlog.connect 'search/:action', :controller => 'search'
  tlog.connect 'tag/*tags', :controller => 'tags', :action => 'view'
  tlog.connect 'tags/:action/:id', :controller => 'tags'

  # conversations legacy
  tlog.connect 'convos', :controller => 'conversations', :action => 'legacy_index'
  tlog.connect 'convos/new', :controller => 'conversations', :action => 'legacy_new'
  tlog.connect 'convos/new/:url', :controller => 'conversations', :action => 'legacy_named_new'
  tlog.connect 'convos/:id', :controller => 'conversations', :action => 'legacy_show'

  # 'static' files
  tlog.style 'style/:revision.css', :action => 'style', :requirements => { :revision => /\d+/ }  
  tlog.robots 'robots.txt', :controller => 'tlog', :action => 'robots'
  tlog.foaf 'foaf.rdf', :controller => 'tlog', :action => 'foaf'
  
  tlog.day ':year/:month/:day', :controller => 'tlog', :action => 'daylog', :requirements => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ }
  
  tlog.next_day ':year/:month/:day/next', :controller => 'tlog', :action => 'next_day', :requirements => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ }
  tlog.prev_day ':year/:month/:day/prev', :controller => 'tlog', :action => 'prev_day', :requirements => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ }

  tlog.tlog_feed 'feed/:action.xml', :controller => 'tlog_feed'
  tlog.tlog_feed_protected 'feed/:key/:action.xml', :controller => 'tlog_feed'

  tlog.private_entries 'private', :action => 'private'
  tlog.anonymous_entries 'anonymous', :action => 'anonymous'

  tlog.resources :entries, :member => { :subscribe => :post, :unsubscribe => :post, :metadata => :get, :mentions => :get }, :collection => { :tags => :get, :relationship => :post } do |entry|
    entry.resources :comments, :member => { :report => :post, :blacklist => :post, :erase => :post, :restore => :post }, :new => { :preview => :post }
    entry.resources :tags, :controller => 'entry_tags'
  end

  tlog.resources :faves, :controller => 'faves'
end

www_settings = lambda do |www|  
  www.connect '', :controller => 'main', :action => 'index'

  www.connect 'premium', :controller => 'main', :action => 'premium'
  www.connect 'settings', :controller => 'main', :action => 'settings'
  www.connect 'publish/:type', :controller => 'main', :action => 'publish'
  www.main_feed_last 'main/feed/last/:rating/:kind.xml', :controller => 'main_feed', :action => 'last', :requirements => { :rating => /[a-z]{3,20}/ }
  www.main_feed 'main/feed/:action.xml', :controller => 'main_feed'
  www.last_day 'main/last/:year/:month/:day/:rating/:kind', :controller => 'main', :action => 'last', :rating => 'default', :kind => 'default', :requirements => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ }
  www.last 'main/last/:rating/:kind', :controller => 'main', :action => 'last', :rating => 'default', :kind => 'default'
  www.hot 'main/hot/:kind', :controller => 'main', :action => 'hot', :kind => 'default'
  www.anonymous 'main/anonymous/:action/:id', :controller => 'anonymous'
  www.tagged 'main/tagged/:tag/:page', :controller => 'main', :action => 'tagged', :page => 1, :requirements => { :page => /\d+/ }
  www.connect 'main/:action/:page', :controller => 'main', :page => /\d+/
  www.main 'main/:action', :controller => 'main'
  www.robots 'robots.txt', :controller => 'main', :action => 'robots'
  www.newyear 'specials/newyear/:action', :controller => 'newyear'
  www.specials 'specials/:action', :controller => 'specials'

  # conversations
  www.resources :messages, :controller => 'messages'
  www.mentions_conversations 'convos/mentions', :controller => 'conversations', :action => 'mentions'
  www.resources :conversations, :as => 'convos', :controller => 'conversations', :collection => { :unreplied => :get, :unviewed => :get, :search => :get, :verify_recipient => :post }, :member => { :subscribe => :post, :unsubscribe => :post, :mav => :post }
  www.named_new_conversation 'convos/new/:url', :controller => 'conversations', :action => 'new', :requirements => { :url => /[a-z0-9]([a-z0-9\-]{1,20})?/i }

  # billing processing
  www.billing 'billing/:action', :controller => 'billing'
  www.connect 'billing/qiwi/update_bill.:format', :controller => 'billing', :action => 'qiwi_update_bill'
  www.connect 'billing/qiwi/fail', :controller => 'billing', :action => 'qiwi_fail'
  www.connect 'billing/qiwi/success', :controller => 'billing', :action => 'qiwi_success'

  # account routes, jf helper methods
  www.login 'account/login', :controller => 'account', :action => 'login'
  www.logout 'account/logout.:format', :controller => 'account', :action => 'logout'
  www.signup 'account/signup', :controller => 'account', :action => 'signup'
  www.lost_password 'account/lost_password', :controller => 'account', :action => 'lost_password'
  www.recover_password 'account/recover_password/:user_id/:secret', :controller => 'account', :action => 'recover_password'
  www.account 'account/:action', :controller => 'account'
  www.confirm 'confirm/:action', :controller => 'confirm'
  www.confirm_code 'confirm/code/:code', :controller => 'confirm', :action => 'code'
  www.search 'search/:action/:id', :controller => 'search'
  www.tag_view 'tag/*tags', :controller => 'tags', :action => 'view'
  www.tags 'tags/:action/:id', :controller => 'tags'
  
  # console, administration controller
  www.namespace :console do |console|
    console.resources :users, :member => { :disable => :post, :destroy => :post, :invitations => :post, :mprevoke => :post, :mpgrant => :post, :restore => :post, :suspect => :get, :reporter => :get }
    console.resources :reports, :member => { :go => :get }
    console.index 'index/:action/:id', :controller => 'index'
    console.root :controller => 'index', :action => 'index'
  end
  
  # www.resources :tastyradio, :controller => 'tastyradio', :collection => { :all => :get, :data => :get }

  www.bookmarklet 'bookmarklet/:action', :controller => 'bookmarklet'

  www.resources :feedbacks, :controller => 'feedbacks', :member => { :publish => :post, :discard => :post }

  www.emailer 'emailer/:method_name/:action', :controller => 'emailer', :defaults => { :action => 'index' } if Rails.env.development?

  www.api 'api/:action/:id', :controller => 'api'
end

ActionController::Routing::Routes.draw do |map|
  map.vote 'vote/:entry_id/:action', :controller => 'vote'
  map.global_fave 'global/fave/:id', :controller => 'faves', :action => 'create'
  map.global 'global/:action.:format', :controller => 'global'
  
  # Assets packages, used only in development
  if Rails.env.development?
    map.css_packages 'packages/css/:name.css', :controller => 'packages', :action => 'css'
    map.js_packages 'packages/js/:name.js', :controller => 'packages', :action => 'js'
  end

  # if Rails.env.production?
    map.with_options :conditions => { :subdomain => /^(www|m|)$/, :domain => Regexp.new(Tlogs::Domains::CONFIGURATION.domains.join('|').gsub('.', '\.')) }, &www_settings

    map.with_options :controller => 'tlog', :conditions => { :subdomain => /^(www|m|)$/, :domain => Regexp.new(Tlogs::Domains::CONFIGURATION.domains.join('|').gsub('.', '\.')) }, :path_prefix => 'users/:current_site', :name_prefix => 'current_site_', &tlog_settings
  
    # это домены пользователей: andy.mmm-tasty.ru, genue.mmm-tasty.ru и так далее
    map.with_options :controller => 'tlog', &tlog_settings
  # else
  #   map.with_options :controller => 'main', &www_settings
  # 
  #   map.with_options :controller => 'tlog', &tlog_settings
  # 
  #   map.with_options :controller => 'tlog', :path_prefix => 'users/:current_site', :name_prefix => 'current_site_', &tlog_settings
  # end

  map.catch_all "*anything", :controller => 'global', :action => 'not_found'
end
