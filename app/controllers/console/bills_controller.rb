class Console::BillsController < ConsoleController
  before_filter :require_admin


  def index
    @title = "Оплаченные и неоплаченные счета"
    @invoices = Invoice.paginate :page => params[:page], :per_page => 100, :order => 'id desc'
  end
end