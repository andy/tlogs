class Console::UsersController < ConsoleController
  before_filter :preload_user, :except => [:index]
  
  
  def index
    @title = 'все пользователи'
    @users = User.paginate :page => params[:page], :per_page => 50, :order => 'id desc'
    
    @signups = User.count(:group => 'UNIX_TIMESTAMP(DATE(created_at))', :conditions => "created_at > '#{1.week.ago.midnight.to_s(:db)}'").values
  end
  
  def show
    @comments_count = @user.comments.count
    @suspect_count  = @user.reports_on.comments.count
    @reports_count  = @user.reports.comments.count

    @title = @user.url
  end
  
  def suspect
    @reports = @user.reports_on.comments.all_inclusive.paginate :page => params[:page], :per_page => 300, :order => 'id desc'    
  end
  
  def reporter
    @reports = @user.reports.comments.all_inclusive.paginate :page => params[:page], :per_page => 300, :order => 'id desc'

    render :action => :suspect
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
      @user = User.find_by_id params[:id]
      
      if @user.nil?
        respond_to do |wants|
          wants.html { redirect_to console_users_path }
          wants.json { render :json => false, :status => 404 }
        end
        false
      end       
    end
end