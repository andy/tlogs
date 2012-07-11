class Console::BillsController < ConsoleController
  
  def index
    @invoices = Invoice.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
  end
end