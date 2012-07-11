class Console::UsersController < ConsoleController
  before_filter :preload_user, :except => [:index]
  
  before_filter :require_comment, :only => [:disable, :destroy, :restore, :mprevoke, :mpgrant]
  
  
  def index
    @title = 'все пользователи'
    @users = User.paginate :page => params[:page], :per_page => 50, :order => 'id desc'
    
    @signups = User.count(:group => 'UNIX_TIMESTAMP(DATE(created_at))', :conditions => "created_at > '#{1.week.ago.midnight.to_s(:db)}'").values
  end
  
  def show
    @changelogs               = @user.changelogs.all :order => 'id desc', :limit => 5
    @comments_enabled_count   = @user.comments.enabled.count
    @comments_disabled_count  = @user.comments.disabled.count
    @suspect_count            = @user.reports_on.comments.count
    @reports_count            = @user.reports.comments.count

    @title = @user.url
  end
  
  def suspect
    @title = "Жалобы на @#{@user.url}"
    @reports = @user.reports_on.comments.all_inclusive.paginate :page => params[:page], :per_page => 300, :order => 'id desc'    
  end
  
  def reporter
    @title = "Жалобы от @#{@user.url}"
    @reports = @user.reports.comments.all_inclusive.paginate :page => params[:page], :per_page => 300, :order => 'id desc'

    render :action => :suspect
  end
  
  def changelogs
    @title = "Изменения в данных @#{@user.url}"
    @changelogs = @user.changelogs.paginate :page => params[:page], :per_page => 50, :order => 'id desc'
  end
  
  def confirm
    render :json => false and return if @user.is_confirmed?
    
    unless params[:password]
      respond_to do |wants|
        wants.html { render :text => 'password required', :status => 403 }
        wants.json { render :json => false, :status => 403 }
      end
    end
    
    @user.log current_user, :confirm, 'подтвердил почту и сменил пароль'
    
    @user.update_attribute :is_confirmed, true
    
    @user.password = params[:password]
    @user.save(false)
    
    render :json => true
  end
  
  def acchange
    duration = params[:duration].to_i || 0

    @user.log current_user, :ac_ban, duration.zero? ? 'снял бан' : "#{@user.is_ac_banned? ? 'забанил' : 'изменил'} на #{duration.pluralize('день', 'дня', 'дней', true)}"
    
    @user.update_attribute :ban_ac_till, duration.zero? ? nil : duration.days.from_now
    
    render :json => true
  end

  def cchange
    duration = params[:duration].to_i || 0

    @user.log current_user, :c_ban, duration.zero? ? 'снял бан' : "#{@user.is_c_banned? ? 'забанил' : 'изменил'} на #{duration.pluralize('день', 'дня', 'дней', true)}"
    
    @user.update_attribute :ban_c_till, duration.zero? ? nil : duration.days.from_now
    
    render :json => true
  end
  
  def wipeout
    render :json => false and return unless @user.is_disabled?

    @user.log current_user, :wipeout, 'все комментарии были удалены'

    Rails.env.development? ? @user.wipeout! : @user.async_wipeout!
    
    render :json => true
  end
  
  def disable    
    @user.log current_user, :disable, params[:comment]

    Rails.env.development? ? @user.disable! : @user.async_disable!

    render :json => true
  end
  
  def restore
    render :json => false and return unless @user.is_disabled?

    @user.log current_user, :restore, params[:comment]

    @user.restore!

    render :json => true
  end
  
  def destroy
    render :json => false and return unless @user.is_disabled?
    
    @user.log current_user, :destroy, params[:comment]

    Rails.env.development? ? @user.destroy : @user.async_destroy!
    
    render :json => true
  end
  
  def invitations
    render :json => 0 and return if params[:inc] != 'true' && @user.invitations_left.zero?
    
    do_increment = params[:inc] == 'true' 

    @user.log current_user, :invitations, "#{do_increment ? 'добавил' : 'отнял'} приглашение"

    @user.send( (do_increment ? :increment! : :decrement!), :invitations_left)
    
    render :json => @user.invitations_left
  end
  
  def mprevoke
    render :json => false and return unless @user.is_mainpageable?

    @user.log current_user, :mprevoke, params[:comment]

    Rails.env.development? ? @user.mprevoke! : @user.async_mprevoke!
    
    render :json => true
  end
  
  def mpgrant
    render :json => false and return if @user.is_mainpageable?

    @user.log current_user, :mpgrant, params[:comment]

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
    
    def require_comment
      unless params[:comment]
        respond_to do |wants|
          wants.html { render :text => 'comment required', :status => 403 }
          wants.json { render :json => false, :status => 403 }
        end
      end
    end
end