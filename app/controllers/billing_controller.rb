class BillingController < ApplicationController
  #
  # QIWI
  # ----
  #
  # Not implemented

  #
  # SMS Online
  # ----------
  #
  # example:
  # {"cn"=>"ua", "rtime"=>"1314109948", "op"=>"ua_mts", "anything"=>["billing", "smsonline"],
  #  "opn"=>"204", "cost"=>"138.4", "mpref"=>"", "action"=>"not_found", "tid"=>"prh1314109948.6002",
  #  "rate"=>"30", "txt"=>"", "zpay"=>"0.0", "pref"=>"tasty", "sn"=>"8404", "repeat"=>"0",
  #  "phone"=>"79038124192", "controller"=>"global", "pay"=>"0", "tg"=>"",
  #  "md5"=>"a6fab7a50a8a4b4e50b0c12db311b48b", "zcost"=>"4.6", "test"=>"1"}
  #
  # doc:
  # http://www.smsonline.ru/docs/smsonline_gate_ru.doc
  #
  # default:
  # pref   -> prefix
  # cn     -> country name
  # op     -> operator name
  # sn     -> short number
  # phone  -> sender phone
  # tid    -> transaction id
  # txt    -> message text
  #
  # extras:
  # test   -> wether this is test or not (should be always ignored)
  # repeat -> this is repeated request (int)
  # opn    -> unique operator number
  # mpref  -> global country prefix (optional)
  # cost   -> cost for sendee (rur, float)
  # zcost  -> cost for sendee (usd, float)
  # rate   -> rate (usd/rur, float)
  # pay    -> how much we get (usd, float)
  # zpay   -> how much we get (usd, float)
  # md5    -> md5 hex (password tid sn op phone pref txt)
  # 
  # request ip:
  # 83.137.50.31, 85.192.45.22, 194.67.81.38, 95.163.74.6
  #
  def smsonline
    render :text => "utf=неверный запрос" and return unless request.post?

    render :text => "utf=неверный адрес запроса" and return unless Rails.env.development? || %w(83.137.50.31 85.192.45.22 194.67.81.38 95.163.74.6).include?(request.remote_ip)

    Invoice.transaction do
      # create bulk transaction data, e.g. log everything
      @invoice = SmsonlineInvoice.new :remote_ip => request.remote_ip,
                                       :metadata => params.slice(*SmsonlineInvoice::METADATA_KEYS),
                                       :state    => 'successful'
    
      if @invoice.valid?
        @invoice.save!
        
        # reload, so we would have .user refreshed with new premium_strftime option
        @invoice.reload

        @invoice.deliver!(current_service)

        render :text => "utf=Премиум-доступ продлен до #{@invoice.user.premium_strftime}. Mmm-tasty.ru, т. 424-00-12"
      else
        Rails.logger.debug "* billing: failed with #{@invoice.errors.full_messages.join(', ')}"

        render :text => "utf=внутренняя ошибка"
      end
    end
  end
  
  # POST /billing/qiwi/update_bill
  def qiwi_update_bill
    code    = QiwiInvoice::SUCCESS
    
    login   = params["Envelope"]["Body"]["updateBill"]["login"]
    pass    = params["Envelope"]["Body"]["updateBill"]["password"]
    txn     = params["Envelope"]["Body"]["updateBill"]["txn"]
    status  = params["Envelope"]["Body"]["updateBill"]["status"].to_i
    
    @invoice = QiwiInvoice.pending.find_by_id(txn)

    # check wether this even exists
    qiwi_soap_reply(QiwiInvoice::ERR_NOT_FOUND) and return if @invoice.nil?

    # check credentials
    qiwi_soap_reply(QiwiInvoice::ERR_AUTH) and return unless @invoice.login == login
    qiwi_soap_reply(QiwiInvoice::ERR_AUTH) and return unless @invoice.secured_password == pass
    
    case status
      when 50..59
        # do nothing, payment in process
      when 60
        # paid by customer, check with remote server if that is true
        qiwi_soap_reply(QiwiInvoice::ERR_BUSY) and return unless @invoice.check_bill

        # mark as paid and proceed
        @invoice.success!
          
        @invoice.deliver!(current_service)
      when 100..200
        # payment failed
        @invoice.metadata[:status] = status

        @invoice.failed!
    end
  end
  
  protected
    def qiwi_soap_reply(code)
      answer = <<-EOF
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ns2:updateBillResponse xmlns:ns2="http://server.ishop.mw.ru/">
      <updateBillResult>#{code.to_s}</updateBillResult>
    </ns2:updateBillResponse>
  </soap:Body>
</soap:Envelope>
EOF
    
      render :xml => answer, :status => 200
    end
end