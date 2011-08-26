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
  DURATION = 29

  METADATA_KEYS = %w(pref cn op sn phone tid txt test repeat opn mpref cost zcost rate pay zpay md5)


  ## validations
  validate :check_required_keys

  validate :check_signature


  ## callbacks
  before_validation :export_attributes
  
  
  ## class methods
  ## public methods
  def summary
    "СМС на номер #{self.metadata[:sn]} стоимостью #{self.amount} руб. (включая НДС 18%)"
  end
  
  def extra_summary
    "оплачено с номера #{self.metadata[:phone]} (#{self.metadata[:op]}), доход #{self.revenue} руб., срок #{self.days.pluralize('день', 'дня', 'дней', true)}"
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
      key = ::SETTINGS[:billing]['smsonline']['key']
      seq = %w(tid sn op phone pref txt)
      str = key + seq.map { |k| metadata[k] }.join

      errors.add_to_base 'неправильная подпись' unless Digest::MD5.hexdigest(str) == metadata[:md5]
    end
    
    def export_attributes
      self.days      = SmsonlineInvoice::DURATION
      self.user      = User.active.find_by_id self.metadata[:txt]
      self.amount    = self.metadata[:cost].to_f || 0
      self.revenue   = self.metadata[:pay].to_f || 0
    end
end
