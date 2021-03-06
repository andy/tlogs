#
# http://www.robokassa.ru/ru/Doc/Ru/Interface.aspx
#
class RoboxInvoice < Invoice
  ## attributes and constants
  OPTIONS = {
    'month' => {
      :days       => 30,
      :days_text  => '1 месяц',
      :discount   => 0,
      :amount     => (DAILY_RATE * 30).ceil,
      :position   => 1
    },
    'quarter' => {
      :days       => 93,
      :days_text  => '3 месяца',
      :discount   => 5,
      :amount     => ((DAILY_RATE * 93) * 0.95).ceil,
      :position   => 2

    },
    'year' => {
      :days       => 365,
      :days_text  => '1 год',
      :discount   => 10,
      :amount     => ((DAILY_RATE * 365) * 0.90).ceil,
      :position   => 3
    }
  }

  TYPES = {
    'ym' => {
      :code     => 'PCR',
      :name     => 'Yandex.Money',
      :desc     => 'Яндекс.Деньги',
      :position => 1
    },
    'cc' => {
      :code     => 'BANKOCEANMR',
      :name     => 'Visa / MasterCard',
      :desc     => 'Кредитной картой (Visa / MasterCard)',
      :position => 2
    },
    'wm' => {
      :code     => 'WMRM',
      :name     => 'WebMoney',
      :desc     => 'WebMoney (WMR, WMZ, WMU, WME и другие валюты)',
      :position => 3
    }
  }

  ## validations
  ## callbacks
  ## class methods
  def self.settings
    ::SETTINGS[:billing]['robox']
  end

  def self.login
    settings['login']
  end

  def self.password1
    settings['password1']
  end

  def self.password2
    settings['password2']
  end

  def self.options
    @@options ||= OPTIONS.map do |name, opts|
      text = "#{opts[:days_text] || opts[:days].pluralize('день', 'дня', 'дней', true)} за #{opts[:amount].pluralize('рубль', 'рубля', 'рублей', true)}"
      text += " (скидка #{opts[:discount]}%)" if opts[:discount] > 0

      OpenStruct.new(:name      => name,
                     :days      => opts[:days],
                     :days_text => opts[:days_text],
                     :amount    => opts[:amount],
                     :position  => opts[:position],
                     :discount  => opts[:discount],
                     :text      => text
                    )
    end
  end

  def self.types
    @@types ||= TYPES.map do |key, opts|

      OpenStruct.new(:key       => key,
                     :name      => opts[:name],
                     :desc      => opts[:desc],
                     :code      => opts[:code],
                     :position  => opts[:position]
                    )

    end
  end

  def self.options_for(key)
    options.find { |opt| opt.name.to_s == key.to_s } || options.sort_by(&:position).first
  end

  def self.type_for(key)
    (key && !key.blank? && types.find { |t| t.key == key }) || nil
  end

  ## public methods
  def login
    self.class.login.to_s
  end

  def password1
    self.class.password1.to_s
  end

  def password2
    self.class.password2.to_s
  end

  def robox_success!
    expand_premium_for_user! && success! if is_pending?
  end

  def robox_failed!
    fail! if is_pending?
  end

  def summary
    "Платеж через ROBOKASSA на сумму #{self.amount.pluralize('рубль', 'рубля', 'рублей', true)}"
  end

  def extra_summary
    txt = ""
    txt += "#{@type.name}. " if type
    txt += "Сервис #{self.is_successful? ? '' : 'не '}продлен на #{self.days.pluralize('день', 'дня', 'дней', true)}"

    txt
  end

  def type
    @type ||= (self.metadata && self.metadata.has_key?(:type)) ? self.class.type_for(self.metadata[:type]) : nil
  end

  def pref_key
    type.try(:key) || 'robox'
  end

  def pref_options
    {}
  end

  def txn_id
    self.id.to_s
  end

  # Production url is https://merchant.roboxchange.com/Index.aspx
  # Test url is http://test.robokassa.ru/Index.aspx
  def payment_url(option, type = nil)
    uri = URI.parse 'https://merchant.roboxchange.com/Index.aspx'

    sig = Digest::MD5.hexdigest [self.class.login, self.amount, self.txn_id, self.password1].join(':')
    uri.query = {
      :MrchLogin      => self.class.login,
      :OutSum         => self.amount,
      :InvId          => self.txn_id,
      :Desc           => "Тейсти-премиум для тлога @#{self.user.url} за #{option.days_text}",
      :SignatureValue => sig,
      :IncCurrLabel   => type.try(:code),
      :Email          => self.user.is_confirmed? ? self.user.email : nil,
      :Culture        => 'ru'
    }.to_query

    uri.to_s
  end

  ## protected
  protected
end
