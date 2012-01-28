class DomainConstraint
  def initialize domains
    @domains = domains
  end

  def matches? request
    @domains.include? request.host
  end
end

class SubdomainConstraint
  def initialize domains
    @domains = domains
  end
  
  def matches? request
    @domains.first { |domain| request.host.ends_with?(domain) }
  end
end

Tasty::Application.routes.draw do
  #
  # These are main page routes visible only on main website
  #
  scope :constraints => DomainConstraint.new(Settings.domains.main) do
    scope :module => :main do
      root :to => 'index#index'
    
      match ':action(/:type)' => 'redirects', :action => /premium|settings|publish/, :format => false
      
      #
      # Messages & Conversations
      #
      resources :messages
      resources :conversations, :as => 'convos', :path => 'convos' do
        collection do
          get 'mentions'
          get 'unreplied'
          get 'unviewed'
          get 'search'
          post 'verify_recipient'
        end
        
        member do
          post 'subscribe'
          post 'unsubscribe'
          post 'mav'
        end
      end
      match 'convos/new/:url' => 'conversations#new', :as => :named_new_conversation, :url => /[a-z0-9]([a-z0-9\-]{1,20})?/i
      
      match 'search/:page' => 'search#index'
    end
    
    #
    # Billing backend
    #
    scope 'billing' do
      scope 'qiwi' do
        match 'update_bill' => 'billing#qiwi_update_bill'
        match 'fail' => 'billing#qiwi_fail'
        match 'success' => 'billing#qiwi_success'
      end
      
      match ':action' => 'billing', :as => 'billing'
    end

    #
    # Authentication & Authorization
    #    
    scope 'account', :module => :auth do
      match 'login' => 'account#login', :as => :login
      match 'logout' => 'account#logout', :as => :logout
      match 'signup' => 'account#signup', :as => :signup
      match 'forgot' => 'account#forgot', :as => :forgot
      match 'recover/:code' => 'account#recover', :as => :recover
      
      match 'confirm/with/:code' => 'confirm#code', :as => :confirm_code
      match 'confirm/:action' => 'confirm', :as => :confirm
    end
    
    #
    # Special & Commerical projects + extras
    #
    scope 'specials', :module => :specials do
      match 'newyear(/:action)' => 'newyear'
      match ':action' => 'index'
    end
  end
  
  #
  # API interaces (routes should be versioned here, v0/v1 and so on to avoid problems
  # with slowly upgrading clients)
  #
  scope :module => 'api', :constraints => DomainConstraint.new(Settings.domains.api) do
    scope 'v0' do
      match '(/:action(/:id))' => 'root'
    end
  end
  
  #
  # This are single tlog routes
  #
  scope :module => :tlog, :constraints => SubdomainConstraint.new(Settings.domains.sub) do
    match '(:page)' => 'index#index', :page => /\d+/

    # this is legacy route
    match 'page/:page' => 'index#index', :page => /\d+/
    
    match 'private(/:page)' => 'index#private', :page => /\d+/, :as => :private_entries
    match 'anonymous(/:page)' => 'index#anonymous', :page => /\d+/, :as => :anonymous_entries

    scope ':year/:month/:day', :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ do
      match '' => 'index#daylog', :as => :day
      match 'next' => 'index#next_day', :as => :next_day
      match 'prev' => 'index#prev_day', :as => :prev_day
    end
    
    resources :entries do
      member do
        post 'subscribe'
        post 'unsubscribe'
        get 'metadata'
        get 'mentions'
      end
      
      collection do
        get 'tags'
        post 'relationship'
      end
      
      resources :comments, :shallow => true do
        post 'preview', :on => :collection
      end
      
    end

    resources :faves

    scope 'feed' do
      match ':key/:action.xml' => 'tlog_feed', :format => false
      match ':action.xml' => 'tlog_feed', :format => false
    end
    
    match 'admin(/:action)' => 'admin', :as => :admin
    
    match 'search(/:action)' => 'search'
    
    match 'tag/*tags' => 'tags#view', :format => false
    match 'tags' => 'tags#index', :format => false
    
    match 'style/:revision.css' => 'index#style', :revision => /\d+/, :format => false, :as => :style
    
    match 'robots.txt' => 'index#robots', :as => :robots, :format => false
    match 'foaf.rdf' => 'index#foaf', :as => :foaf, :format => false
  end
  
  #
  # These are globally accessible routes
  #
  
  # TODO: Publisher must be moved to be accessible through main only
  match 'publish(/:action/(:id))' => 'publish'
  
  # TODO: Settings should be moved to be accessible through main only
  scope 'settings', :module => :settings do
    match 'social(/:action)' => 'social', :as => :settings_social
    match 'sidebar(/:action(/:id))' => 'sidebar', :as => :settings_sidebar
    match 'mobile(/:action(/:id))' => 'mobile', :as => :settings_mobile
    match 'premium(/:action)' => 'premium', :as => :settings_premium
    match '(/:action)' => 'default', :as => :settings
  end
end
