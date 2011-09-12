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
    'ua' => 'Украина'
  }
  
  COUNTRIES = {
    'ru' => 1,
    'ua' => 2
  }
  
  OPERATORS = {
    'beeline' => 1,
    'mts'     => 2,
    'mf'      => 3,
    'tele2'   => 4
  }
  
  CURRENCIES = {
    'RUB'     => 'руб.',
    'USD'     => 'дол.'
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
  
  def self.duration(sn)
    settings['duration'][sn] || 1
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
                                  :value => "#{duration(net.shortnumber).pluralize('день', 'дня', 'дней', true)}\t(#{net.sms_cost_loc.to_f.to_s} #{CURRENCIES[net.currency] || net.currency} без НДС)",
                                  :shortnumber => net.shortnumber,
                                  :position => settings['numbers'].index(net.shortnumber),
                                  :vat => net.vat)

          operator.numbers << number if settings['numbers'].include?(net.shortnumber)
        end
        
        country.operators << operator if operator.numbers.any?
      end

      result << country if country.operators.any?
    end
    
    result
  end
  
  
  ## public methods
  def summary
    "SMS на номер #{self.metadata[:sn]} стоимостью #{self.amount} руб."
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
      %w(tid sn op phone pref txt md5 pay cost).each do |key|
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
      self.days      = SmsonlineInvoice.duration(self.metadata[:sn].to_i)
      self.user      = User.active.find_by_id(self.metadata[:txt][1..-1].to_i) if self.metadata[:txt] && self.metadata[:txt].to_i > 0
      self.amount    = self.metadata[:cost].to_f || 0
      self.revenue   = self.metadata[:pay].to_f || 0
    end
end
