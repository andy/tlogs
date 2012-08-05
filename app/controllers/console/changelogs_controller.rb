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
  
  def ip
    @title = "Общая активность по адресу #{params[:addr]}"
    @changelogs = Changelog.paginate :page => params[:page], :per_page => 100, :order => 'id desc', :conditions => { :ip => params[:addr] }
    
    render :action => 'index'
  end
end