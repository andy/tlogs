class LoveController < ApplicationController
  before_filter :require_current_user, :except => [:result]
  before_filter :require_confirmed_current_user, :except => [:result]

  before_filter :preload_robox_settings
  
  before_filter :validate_robox_posting, :only => [:result, :success, :fail]

  helper :settings
  layout "settings"

  def index
    if request.post?
      transaction = current_user.transactions.build(:amount => params[:amount])
      transaction.save!
      
      uri = URI::parse('http://test.robokassa.ru/Index.aspx')
      
      uri_params = {
        'MrchLogin'       => @robox_settings[:login],
        'OutSum'          => transaction.amount,
        'InvId'           => transaction.id,
        'Desc'            => @robox_settings[:desc],
        'Culture'         => 'ru',
        'SignatureValue'  => Digest::MD5.hexdigest("#{@robox_settings[:login]}:#{transaction.amount}:#{transaction.id}:#{@robox_settings[:secret_one]}")
      }
      
      redirect_to uri.to_s + '?' + uri_params.to_query
    end
    
    @show_form = current_user.transactions.success.count.zero?
  end
  
  def result
    @transaction.update_attributes :state => 'success'

    Emailer.deliver_love(current_service, transaction)

    render :text => "OK#{@transaction.id}"
  end
  
  def success
    redirect_to love_url
  end
  
  def fail
    @transaction.update_attributes :state => 'fail'
    
    redirect_to love_url
  end
  
  protected
    def preload_robox_settings
      @robox_settings = YAML.load_file(File.join(Rails.root, 'config/robox.yml')).symbolize_keys

      @robox_settings.assert_valid_keys(:login, :desc, :secret_one, :secret_two)
    end
    
    def validate_robox_posting
      return false unless request.post?
   
      secret = @robox_settings[(params[:action] == 'result') ? :secret_two : :secret_one]
      return false if params[:SignatureValue] != Digest::MD5.hexdigest("#{params[:OutSum]}:#{params[:InvId]}:#{secret}")
      
      @transaction = Transaction.find params[:InvId]
      
      true
    end
end