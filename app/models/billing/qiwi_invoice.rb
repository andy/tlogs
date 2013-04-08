# == Schema Information
# Schema version: 20110816190509
#
# Table name: invoices
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null, indexed
#  state      :string(255)     not null
#  type       :string(255)     not null
#  metadata   :string(255)     not null
#  amount     :float           default(0.0), not null
#  revenue    :float           default(0.0), not null
#  days       :integer(4)      default(0), not null
#  remote_ip  :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

#
# Qiwi through SOAP API, as documented in https://ishop.qiwi.ru/docs/OnlineStoresProtocols_SOAP.pdf
#
# Codes:
# 50  created
# 52  transaction in progress
# 60  paid
# 150 cancelled (terminal error)
# 151 cancelled (by customer)
# 160 cancelled
# 161 cancelled (timed out)
#
# General code namespace:
# 50..59    created
# 60        paid
# 100..200  cancelled
#
class QiwiInvoice < Invoice
  ## attributes and constants
  EXPIRES_IN    = 2.weeks

  SUCCESS       = 0

  ERR_BUSY      = 13
  ERR_NOT_FOUND = 210
  ERR_AUTH      = 150
  ERR_TOO_SMALL = 241
  ERR_UNKNOWN   = 300

  OPTIONS = {
    'small' => {
      :days       => 30,
      :days_text  => '1 месяц',
      :discount   => 0,
      :amount     => (DAILY_RATE * 30).ceil,
      :position   => 1
    },
    'medium' => {
      :days       => 93,
      :days_text  => '3 месяца',
      :discount   => 5,
      :amount     => ((DAILY_RATE * 93) * 0.95).ceil,
      :position   => 2
      
    },
    'large' => {
      :days       => 365,
      :days_text  => '1 год',
      :discount   => 10,
      :amount     => ((DAILY_RATE * 365) * 0.90).ceil,
      :position   => 3
    }
  }
  
  ## validations
  ## callbacks
  ## class methods
  def self.settings
    ::SETTINGS[:billing]['qiwi']
  end

  def self.login
    settings['login']
  end
  
  def self.password
    settings['password']
  end
  
  def self.options
    @@options ||= OPTIONS.map do |name, opts|
      text = "#{opts[:days_text] || opts[:days].pluralize('день', 'дня', 'дней', true)} за #{opts[:amount].pluralize('рубль', 'рубля', 'рублей', true)}"
      text += " (скидка #{opts[:discount]}%)" if opts[:discount] > 0

      OpenStruct.new(:name      => name,
                     :days      => opts[:days],
                     :amount    => opts[:amount],
                     :position  => opts[:position],
                     :discount  => opts[:discount],
                     :text      => text
                    )
    end
  end
  
  def self.options_for(key)
    options.find { |opt| opt.name.to_s == key.to_s } || options.sort_by(&:position).first
  end

  # def self.create_soap_bill(user, phone, amount = 149)
  #   require 'savon'
  # 
  #   invoice = nil
  # 
  #   QiwiInvoice.transaction do
  #     invoice = QiwiInvoice.create! :user => user.id, :state => 'pending', :amount => amount, :revenue => amount, :days => 29, :metadata => { :protocol => 'soap', :phone => phone, :expires => EXPIRES_IN.from_now.to_s(:db) }
  #       
  #     body = {
  #       :login      => invoice.login,
  #       :password   => invoice.password,
  #       :user       => phone.gsub(/[^0-9]/, ''),
  #       :amount     => invoice.amount,
  #       :comment    => "Подписка на Тейсти-Премиум для аккаунта #{user.url}",
  #       :txn        => invoice.txn_id,
  #       :lifetime   => EXPIRES_IN.from_now.beginning_of_day.strftime('%d.%m.%Y %H:%M:%S'),
  #       :alarm      => 0, 
  #       :create     => true
  #     }
  #     
  #     client = Savon::Client.new 'http://ishop.qiwi.ru/services/ishop?wsdl'
  #     response = client.create_bill { |soap| soap.body = body }
  #     
  #     raise 'Incorrect response' if response.to_hash[:create_bill_response][:create_bill_result].to_i != 0
  #   end
  #   
  #   invoice
  # end


  ## public methods  
  def check_bill
    require 'savon'

    client = Savon::Client.new 'http://ishop.qiwi.ru/services/ishop?wsdl'

    response = client.check_bill do |soap|
      soap.body = {
        :login    => self.login,
        :password => self.password,
        :txn      => self.txn_id
      }
    end

    answer = response.to_hash[:check_bill_response]

    answer[:status].to_i == 60 && answer[:amount].to_f == self.amount
  end
  
  def login
    self.class.login.to_s
  end
  
  def password
    self.class.password.to_s
  end
  
  def secured_password
    ::Digest::MD5.hexdigest(self.txn_id.to_s + ::Digest::MD5.hexdigest(self.password).upcase).upcase
  end
  
  def qiwi_success!
    expand_premium_for_user! && success! if is_pending?
  end
  
  def qiwi_failed!
    fail! if is_pending?
  end

  def summary
    "Платеж через QIWI-кошелек на сумму #{self.amount.pluralize('рубль', 'рубля', 'рублей', true)}"
  end
  
  def extra_summary
    "Сервис #{self.is_successful? ? '' : 'не '}продлен на #{self.days.pluralize('день', 'дня', 'дней', true)}"
  end
  
  def pref_key
    'qiwi'
  end
  
  def pref_options
    self.metadata[:phone]
  end
  
  def txn_id
    "qiwi-#{self.id}"
  end
  
  def to_json
    {
      :to     => self.metadata[:phone],
      :summ   => self.amount,
      :com    => "Подписка на Тейсти-премиум для аккаунта #{self.user.url} на #{self.days.pluralize('день', 'дня', 'дней', true)}",
      :txn_id => self.txn_id
    }.to_json    
  end

  
  ## protected
  protected
end
