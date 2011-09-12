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

    unless Rails.env.development? || SmsonlineInvoice.settings['servers'].include?(request.remote_ip)
      HoptoadNotifier.notify(
        :error_class    => 'SmsonlineInvoice',
        :error_message  => "SmsonlineInvoice: invalid remote address (#{request.remote_ip})",
        :parameters     => params
      )
      
      render :text => "utf=неверный адрес запроса"
      return
    end

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
      elsif @invoice.errors.on(:user)
        HoptoadNotifier.notify(
          :error_class    => 'SmsonlineInvoice',
          :error_message  => "SmsonlineInvoice: user not found (#{params[:txt]})",
          :parameters     => params
        )
        render :text => "utf=Ошибка, пользователь не найден."
      else
        HoptoadNotifier.notify(
          :error_class    => 'SmsonlineInvoice',
          :error_message  => "SmsonlineInvoice: other error (#{@invoice.errors.full_messages.join(', ')})",
          :parameters     => params
        )
        render :text => "utf=Ошибка! Обратитесь, пожалуйста, в службу поддержки premium@mmm-tasty.ru."
      end
    end
  end
  
  # POST /billing/qiwi/update_bill
  def qiwi_update_bill
    code    = QiwiInvoice::SUCCESS
    testing = false
    
    login   = params["Envelope"]["Body"]["updateBill"]["login"]
    pass    = params["Envelope"]["Body"]["updateBill"]["password"]
    txn     = params["Envelope"]["Body"]["updateBill"]["txn"].gsub('qiwi-', '').to_i
    status  = params["Envelope"]["Body"]["updateBill"]["status"].to_i
    
    testing = true if pass.blank?

    QiwiInvoice.transaction do
      @invoice = QiwiInvoice.pending.find_by_id(txn)
      @invoice.metadata[:testing] = true if testing

      # check wether this even exists
      qiwi_soap_reply(QiwiInvoice::ERR_NOT_FOUND, params) and return if @invoice.nil?

      # check credentials
      qiwi_soap_reply(QiwiInvoice::ERR_AUTH, params) and return unless @invoice.login == login
      qiwi_soap_reply(QiwiInvoice::ERR_AUTH, params) and return unless testing || @invoice.secured_password == pass
    
      case status
        when 50..59
          # do nothing, payment in process
        when 60
          # paid by customer, check with remote server if that is true
          qiwi_soap_reply(QiwiInvoice::ERR_BUSY, params) and return unless @invoice.check_bill

          # mark as paid and proceed
          @invoice.success!
          
          @invoice.deliver!(current_service)
        when 100..200
          # payment failed
          @invoice.metadata[:status] = status

          @invoice.failed!
      end
    end
    
    qiwi_soap_reply(code)
  end
  
  protected
    def qiwi_soap_reply(code, params = {})
      answer = <<-EOF
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ns2:updateBillResponse xmlns:ns2="http://server.ishop.mw.ru/">
      <updateBillResult>#{code.to_s}</updateBillResult>
    </ns2:updateBillResponse>
  </soap:Body>
</soap:Envelope>
EOF

      if code != QiwiInvoice::SUCCESS
        HoptoadNotifier.notify(
          :error_class    => 'QiwiInvoice',
          :error_message  => "QiwiInvoice: erronous request (code: #{code})",
          :parameters     => params
        )
      end
    
      render :xml => answer, :status => 200
    end
end