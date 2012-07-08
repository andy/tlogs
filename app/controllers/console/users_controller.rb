class Console::UsersController < ConsoleController
  
  def index
    @title = 'все пользователи'
    @users = User.paginate :page => params[:page], :per_page => 50, :order => 'id desc'
  end
  
  def show
    @user   = User.find params[:id]    
    @title  = @user.url
  end
end