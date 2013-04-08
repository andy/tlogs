class Console::ReportsController < ConsoleController
  before_filter :preload_report, :except => [:index]


  def index
    @title = 'жалобы'

    @reports = Report.comments.all_inclusive.paginate(:page => params[:page], :per_page => 300, :order => 'id desc')
  end
  
  def go
    case @report.content_type
    when 'Comment'
      comment = @report.content
      entry   = comment.entry
      
      if entry.is_anonymous?
        redirect_to service_url("/main/anonymous/show/#{entry.id}#comment#{comment.id}")
      else
        redirect_to user_url(entry.author, entry_path(entry)).to_s + "#comment#{comment.id}"
      end
    else
      render :text => 'errornous content type', :status => 500
    end
  end
  
  protected
    def preload_report
      @report = Report.find params[:id]
    end
end