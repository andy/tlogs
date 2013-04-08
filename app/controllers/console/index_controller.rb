class Console::IndexController < ConsoleController
  def index
    @title = 'консоль модератора'
  end
  
  def lookup
    query = params[:query] || ''

    # match ip address
    redirect_to ip_console_changelogs_path(:addr => query) and return if query =~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\Z/i
    
    # match url (extract first part of hostname)
    query = URI.parse(query).host.split(/\./)[0] if query.starts_with?('http://')    
    
    user   = User.find_by_id(query) if query =~ /^\d+$/
    user ||= User.find_by_email(query) if query =~ /@/
    user ||= User.find_by_url(query)
    
    render :action => 'not_found', :status => 404 and return unless user

    redirect_to console_user_path(user)
  end
  
  def faq
    render :action => 'not_found', :status => 404
  end
end