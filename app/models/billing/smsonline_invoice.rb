# encoding: utf-8
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
# As specified by SMS Online
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
class SmsonlineInvoice < Invoice
  ## attributes and constants
  METADATA_KEYS = %w(pref cn op sn phone tid txt test repeat opn mpref cost zcost rate pay zpay md5)

  COUNTRY_NAMES = {
    'ru' => 'Россия',
    'ua' => 'Украина',
    'by' => 'Беларусь',
    'kz' => 'Казахстан',
    'md' => 'Молдова'
  }
  
  COUNTRIES = {
    'ru' => 1,
    'ua' => 2,
    'by' => 3,
    'kz' => 4,
    'md' => 5
  }
  
  OPERATORS = {
    'beeline' => 1,
    'mts'     => 2,
    'mf'      => 3,
    'tele2'   => 4
  }
  
  CURRENCIES = {
    'RUB'     => 'руб.',
    'USD'     => 'дол.',
    'BYR'     => 'руб.'
  }

  ## validations
  validate :check_required_keys

  validate :check_signature


  ## callbacks
  before_validation :export_attributes
  
  
  ## class methods
  def self.settings
    ::SETTINGS[:billing]['smsonline']
  end
  
  def self.duration(net)
    (settings['duration'][net.country][net.shortnumber] || 1) rescue 1
  end
  
  def self.networks
    doc = Hpricot.XML(File.read(File.join(Rails.root, settings['prices'])))
    
    result = []
    (doc/:network).each do |network|
      result << OpenStruct.new(:country => (network/:country).text,
                                  :shortnumber => (network/:shortnumber).text.to_i,
                                  :operator_name => (network/:operator_name).text,
                                  :operator_code => (network/:operator_code).text,
                                  :operator_id => (network/:operator_id).text.to_i,
                                  :vat => (network/:vat).text,
                                  :sms_cost_vat => (network/:sms_cost_vat).text,
                                  :sms_cost_loc => (network/:sms_cost_loc).text,
                                  :payout_res => (network/:payout_res).text,
                                  :currency => (network/:currency).text
                              )
    end

    result
  end
  
  def self.countries_for_select
    result = []

    networks.group_by(&:country).each do |c_name, c_nets|
      country = OpenStruct.new(:name => c_nets.first.country,
                               :value => COUNTRY_NAMES[c_nets.first.country] || c_nets.first.country,
                               :position => COUNTRIES[c_nets.first.country] || (COUNTRIES.values.max + 1),
                               :operators => [])
      
      c_nets.group_by(&:operator_id).each do |o_name, o_nets|
        operator = OpenStruct.new(:name => [o_nets.first.country, o_nets.first.operator_code].join('_'),
                                  :value => o_nets.first.operator_name,
                                  :position => OPERATORS[o_nets.first.operator_code] || (OPERATORS.values.max + 1),
                                  :numbers => [])
        
        o_nets.each do |net|
          number = OpenStruct.new(:name => [net.country, net.operator_code, net.shortnumber].join('_'),
                                  :value => "#{duration(net).pluralize('день', 'дня', 'дней', true)}\t(#{net.sms_cost_vat.to_f.to_s} #{CURRENCIES[net.currency] || net.currency} с НДС)",
                                  :shortnumber => net.shortnumber,
                                  :position => settings['numbers'][net.country].index(net.shortnumber),
                                  :vat => net.vat)

          operator.numbers << number if settings['numbers'][net.country].include?(net.shortnumber)
        end
        
        country.operators << operator if operator.numbers.any?
      end if settings['countries'].include?(country.name)

      result << country if country.operators.any?
    end
    
    result
  end
  
  
  ## public methods
  def summary
    "SMS на номер #{self.metadata[:sn]} (#{self.amount} #{self.metadata[:currency]} с НДС)"
  end
  
  def extra_summary
    "оплачено с номера #{self.metadata[:phone]} (#{self.metadata[:op]}), доход #{self.revenue} руб., срок #{self.days.pluralize('день', 'дня', 'дней', true)}"
  end
  
  def pref_key
    'sms'
  end
  
  def pref_options
    [self.metadata[:cn], self.metadata[:op], self.metadata[:sn]].join('_')
  end
  

  ## protected
  protected
    def check_required_keys
      %w(tid cn sn op phone pref txt md5).each do |key|
        errors.add_to_base "обязательный параметр #{key} отсутствует" if metadata[key].nil?
      end
    end

    # checksum checking according to their documentation
    def check_signature
      key = self.class.settings['key']
      seq = %w(tid sn op phone pref txt)
      str = key + seq.map { |k| metadata[k] }.join

      errors.add_to_base 'неправильная подпись' unless Digest::MD5.hexdigest(str) == metadata[:md5]
    end
    
    def export_attributes
      net            = SmsonlineInvoice.networks.find { |n| n.country == self.metadata[:cn] && n.shortnumber == self.metadata[:sn].to_i }
      
      if net
        self.metadata_will_change!
        self.metadata[:currency] = net.currency
        self.days      = SmsonlineInvoice.duration(net)
        self.user      = User.active.find_by_id(self.metadata[:txt][1..-1].to_i) if self.metadata[:txt] && self.metadata[:txt].to_i > 0
        self.amount    = net.sms_cost_vat
        self.revenue   = net.payout_res
      else
        errors.add_to_base "не удалось найти номер"
      end
    end
end
