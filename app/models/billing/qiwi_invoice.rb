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
  EXPIRES_IN = 2.weeks

  SUCCESS       = 0

  ERR_BUSY      = 13
  ERR_NOT_FOUND = 210
  ERR_AUTH      = 150
  ERR_TOO_SMALL = 241
  ERR_UNKNOWN   = 300

  
  ## validations
  ## callbacks
  ## class methods
  def self.login
    ::SETTINGS[:billing]['qiwi']['login']
  end
  
  def self.password
    ::SETTINGS[:billing]['qiwi']['password']
  end
 
  def self.create_bill(user, phone, amount = 149)
    invoice = nil

    QiwiInvoice.transaction do
      invoice = QiwiInvoice.create! :user => user.id, :state => 'pending', :amount => amount, :revenue => amount, :days => 29, :metadata => { :phone => phone, :expires => EXPIRES_IN.from_now }
        
      body = {
        :login      => invoice.login,
        :password   => invoice.password,
        :user       => phone.gsub(/[^0-9]/, ''),
        :amount     => invoice.amount,
        :comment    => 'Подписка на Тейсти-Премиум',
        :txn        => invoice.id,
        :lifetime   => EXPIRES_IN.from_now.beginning_of_day.strftime('%d.%m.%Y %H:%M:%S'),
        :alarm      => 0, 
        :create     => true
      }
      
      client = Savon::Client.new 'http://ishop.qiwi.ru/services/ishop?wsdl'
      response = client.create_bill { |soap| soap.body = body }
      
      raise 'Incorrect response' if response.to_hash[:create_bill_response][:create_bill_result].to_i != 0
    end
    
    invoice
  end


  ## public methods  
  def check_bill
    client = Savon::Client.new 'http://ishop.qiwi.ru/services/ishop?wsdl'

    response = client.check_bill do |soap|
      soap.body = {
        :login    => self.login,
        :password => self.password,
        :txn      => self.id
      }
    end

    answer = response.to_hash[:check_bill_response]

    answer[:status].to_i == 60 && answer[:amount].to_f == self.amount
  end
  
  def login
    self.class.login
  end
  
  def password
    self.class.password
  end
  
  def secured_password
    ::Digest::MD5.hexdigest(self.id.to_s + ::Digest::MD5.hexdigest(self.password).upcase).upcase
  end

  def summary
  end
  
  def extra_summary
  end
  
  ## protected
  protected
end