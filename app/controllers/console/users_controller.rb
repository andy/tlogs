class Console::UsersController < ConsoleController
  before_filter :preload_user, :except => [:index]
  
  
  def index
    @title = 'все пользователи'
    @users = User.paginate :page => params[:page], :per_page => 50, :order => 'id desc'
  end
  
  def show
    @title = @user.url
  end
  
  def disable
    Rails.env.development? ? @user.disable! : @user.async_disable!

    render :json => true
  end
  
  def restore
    @user.restore!

    render :json => true
  end
  
  def destroy
    Rails.env.development? ? @user.destroy : @user.async_destroy!
    
    render :json => true
  end
  
  def invitations
    render :json => 0 and return if params[:inc] != 'true' && @user.invitations_left.zero?

    @user.send( ((params[:inc] == 'true') ? :increment! : :decrement!), :invitations_left)
    
    render :json => @user.invitations_left
  end
  
  def mprevoke
    Rails.env.development? ? @user.mprevoke! : @user.async_mprevoke!
    
    render :json => true
  end
  
  def mpgrant
    @user.mpgrant!
    
    render :json => true
  end
  
  protected
    def preload_user
      @user = User.find params[:id]
    end
end