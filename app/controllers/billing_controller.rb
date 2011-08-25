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

    Transaction.transaction do
      supported_options = %w(pref cn op sn phone tid txt test repeat opn mpref cost zcost rate pay zpay md5)
      options           = params.slice(*supported_options)

      # create bulk transaction data, e.g. log everything
      bt = BulkTransaction.create :service => 'smsonline', :remote_ip => request.remote_ip, :metadata => options
    
      # check wether transaction is valid or not
      render :text => "utf=внутренняя ошибка" and return unless bt.valid?
    
      # try to restore original transaction this sms was about
      user = User.find_by_id(options[:txt])

      # if there is no such transaction — ignore this
      render :text => "utf=неправильный код" and return if user.nil?
      
      txn = Transaction.create :user => user, :amount => bt.txn_amount, :state => 'success', :service => bt.service
      txn.bulk_transactions << bt
      
      # update premium expiration date and give 8 hour buffer
      user.premium_till = ((user.premium_till || Time.now) + 29.days).end_of_day + 8.hours
      user.save!

      render :text => "utf=Премиум-доступ продлен до #{user.premium_till.yesterday.strftime '%d %h %Y'}. Mmm-tasty.ru, т. 424-00-12"
    end
  end
end