class Console::IndexController < ConsoleController
  def index
    @title = 'консоль модератора'
  end
  
  def lookup
    query = params[:query]
    
    user   = User.find_by_id(query) if query =~ /^\d+$/
    user ||= User.find_by_email(query) if query =~ /@/
    user ||= User.find_by_url(query)
    
    render :action => 'not_found', :status => 404 and return unless user

    redirect_to console_user_path(user)
  end  
end