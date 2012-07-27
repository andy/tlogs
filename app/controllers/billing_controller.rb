class BillingController < ApplicationController
  before_filter :require_current_user, :only => [:robox_success, :robox_failure]
  
  before_filter :robox_preload, :only => [:robox_result, :robox_success]


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
      Airbrake.notify(
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
        Airbrake.notify(
          :error_class    => 'SmsonlineInvoice',
          :error_message  => "SmsonlineInvoice: user not found (#{params[:txt]})",
          :parameters     => params
        )
        render :text => "utf=Ошибка, пользователь не найден."
      else
        Airbrake.notify(
          :error_class    => 'SmsonlineInvoice',
          :error_message  => "SmsonlineInvoice: other error (#{@invoice.errors.full_messages.join(', ')})",
          :parameters     => params
        )
        render :text => "utf=Ошибка! Обратитесь, пожалуйста, в службу поддержки premium@mmm-tasty.ru."
      end
    end
  end

  
  #
  # ROBOX
  # -----
  #  
  # POST /billing/robox/result [API endpoint]
  def robox_result
    if @invoice.is_pending?
      @invoice.robox_success!
    
      @invoice.deliver!(current_service)
    
      render :text => "OK#{@invoice.id}"
    else
      render :text => 'FAIL'
    end
  end
  
  # POST /billing/robox/success [Customer endpoint]
  def robox_success
    flash[:good] = @invoice.summary + ' успешно проведен.'
    
    redirect_to user_url(current_user, settings_premium_path)
  end
  
  # POST /billing/robox/failure [Customer endpoint]
  def robox_failure
    flash[:bad] = 'Оплата через ROBOX отменена.'

    redirect_to user_url(current_user, settings_premium_path)
  end

  
  #
  # QIWI
  # ----
  #
  def qiwi_fail
    flash[:bad] = 'К сожалению, при оплате произошла какая-то ошибка.'

    redirect_to current_user ? user_url(current_user, settings_premium_path) : service_url(login_path(:noref => 1))
  end
  
  def qiwi_success
    flash[:good] = 'Великолепно! Тейсти-премиум успешно оплачен через QIWI-кошелек'

    redirect_to current_user ? user_url(current_user, settings_premium_path) : service_url(login_path(:noref => 1))
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

      # check wether this even exists
      qiwi_soap_reply(QiwiInvoice::ERR_NOT_FOUND, params) and return if @invoice.nil?

      # check credentials
      qiwi_soap_reply(QiwiInvoice::ERR_AUTH, params) and return unless @invoice.login == login
      qiwi_soap_reply(QiwiInvoice::ERR_AUTH, params) and return unless testing || @invoice.secured_password == pass

      @invoice.metadata_will_change!
      @invoice.metadata[:testing] = true if testing
    
      case status
        when 50..59
          # do nothing, payment in process
        when 60
          # paid by customer, check with remote server if that is true
          qiwi_soap_reply(QiwiInvoice::ERR_BUSY, params) and return unless testing || @invoice.check_bill

          # mark as paid and proceed
          @invoice.qiwi_success!
          
          @invoice.deliver!(current_service)
        when 100..200
          # payment failed
          @invoice.metadata_will_change!
          @invoice.metadata[:status] = status

          @invoice.qiwi_failed!
      end
    end
    
    qiwi_soap_reply(code)
  end
  
  protected
    def robox_preload
      robox_reply_with_fail("invalid request", params) and return false unless request.post?
      
      amount    = params[:OutSum]
      txn_id    = params[:InvId]
      sig       = params[:SignatureValue]
      pass      = params[:action] == 'robox_result' ? RoboxInvoice.password2 : RoboxInvoice.password1

      our_sig = Digest::MD5.hexdigest [amount, txn_id, pass].join(':')

      robox_reply_with_fail("erronous request (signature mismatch)", params) and return false if our_sig.downcase != sig.downcase      
      
      @invoice = RoboxInvoice.find_by_id(txn_id)

      robox_reply_with_fail("invoice not found", params) and return false if @invoice.nil?
      
      robox_reply_with_fail("invalid amount (expected #{@invoice.amount})", params) and return false if amount.to_f != @invoice.amount
      
      true
    end
  
    def robox_reply_with_fail(message, params = {})
      Airbrake.notify(
        :error_class    => 'RoboxInvoice',
        :error_message  => "RoboxInvoice: #{message}",
        :parameters     => params || {}
      )
      
      render :text => "FAIL", :status => 200
    end
  
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
        Airbrake.notify(
          :error_class    => 'QiwiInvoice',
          :error_message  => "QiwiInvoice: erronous request (code: #{code})",
          :parameters     => params
        )
      end
    
      render :xml => answer, :status => 200
    end
end