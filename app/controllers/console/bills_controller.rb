class Console::BillsController < ConsoleController
  
  def index
    @title = "Оплаченные и неоплаченные счета"
    @invoices = Invoice.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
  end
end