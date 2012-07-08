class Console::ReportsController < ConsoleController
  def index
    @title = 'жалобы'

    @reports = Report.comments.all_inclusive.paginate(:page => params[:page], :per_page => 300, :order => 'id desc')
  end  
end