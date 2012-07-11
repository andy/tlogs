class Console::ChangelogsController < ConsoleController
  
  def index
    @title = 'общая активность пользователей и админов'
    @changelogs = Changelog.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
  end
end