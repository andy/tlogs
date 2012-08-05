class Console::ChangelogsController < ConsoleController
  
  def index
    @title = 'Общая активность'
    @changelogs = Changelog.noauth.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
  end
  
  def all
    @title = 'Вся активность'
    @changelogs = Changelog.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
    
    render :action => 'index'
  end
  
  def auth
    @title = 'Авторизационная активность'
    @changelogs = Changelog.auth.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
    
    render :action => 'index'
  end
  
  # suspicious ip addresses
  def ipicious
    @title      = "Подозрительная активность"
    @hours      = params[:hours] ? params[:hours] : 24
    @threshold  = params[:threshold] ? params[:threshold] : 10

    @ips = Changelog.connection.select_rows("SELECT ip, count(*) AS c FROM changelogs WHERE ip IS NOT NULL AND created_at > '#{@hours.to_i.hours.ago.to_s(:db)}' GROUP BY ip HAVING c >= #{@threshold.to_i} ORDER BY c DESC")
  end
  
  def ip
    @title = "Общая активность по адресу #{params[:addr]}"
    @changelogs = Changelog.paginate :page => params[:page], :per_page => 100, :order => 'id desc', :conditions => { :ip => params[:addr] }
    
    render :action => 'index'
  end
end