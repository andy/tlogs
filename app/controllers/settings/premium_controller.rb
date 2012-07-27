class Settings::PremiumController < ApplicationController
  before_filter :require_current_user, :require_owner
  before_filter :require_confirmed_current_user
  before_filter :require_premium, :except => [:index, :pay, :invoices, :sms_update, :qiwi_init_bill, :robox_init_bill]

  protect_from_forgery

  helper :settings
  layout "settings"


  def index
  end
  
  def accounts
    @accounts = User.find(current_site.linked_with)
  end
  
  def accounts_popup
    render :layout => false
  end

  def link
    render :nothing => true and return unless request.post?

    @user = User.authenticate(params[:email], params[:password])
    
    if @user && !@user.is_openid?
      current_site.link_with(@user)
      
      render :json => true
    else
      render :json => false
    end
  end
  
  def unlink
    render :nothing => true and return unless request.post?

    @user = User.find_by_url(params[:url])
    current_site.unlink_from(@user) if @user
    
    current_site.reload
    
    render :update do |page|
      if current_site.can_switch?
        page.visual_effect :highlight, "t-accounts-link-#{@user.url.downcase}", :duration => 0.3
        page.visual_effect :fade, "t-accounts-link-#{@user.url.downcase}", :duration => 0.3
      else
        page << "jQuery('.accounts').hide(1000);"
      end
    end
  end

  def background
    ts = current_site.tlog_settings
    
    if request.post?
      if params[:image]
        Background.transaction do
          bg = Background.create :user => current_site, :image => params[:image]
          bg.tlog_settings << ts if bg
          bg.update_attribute(:gray_logo, params[:gray_logo])
        end

        flash[:good] = 'Великолепно, изображение добавлено!'
        redirect_to user_url(current_site, settings_premium_path(:action => 'background'))
      elsif params[:id]
        Background.transaction do
          bg = Background.find(params[:id], :conditions => "is_public = 1 OR user_id = #{current_site.id}")
          bg.tlog_settings << ts if bg
        end
        
        render :json => {:success => true, :gray_logo => Background.find(params[:id], :conditions => "is_public = 1 OR user_id = #{current_site.id}").gray_logo }
      else
        redirect_to user_url(current_site, settings_premium_path(:action => 'background'))
      end
    elsif request.delete?
      Background.transaction do
        ts = current_site.tlog_settings
        bg = Background.find(params[:id], :conditions => "is_public = 1 OR user_id = #{current_site.id}")
        bg.destroy unless bg.is_public?
        ts.update_attribute(:background_id, nil) if bg.id == ts.background_id
      end
      
      render :json => true
    else
      if current_site.tlog_settings.background_id then
        bg = Background.find(current_site.tlog_settings.background_id, :conditions => "is_public = 1 OR user_id = #{current_site.id}")
        @gray_logo = bg.gray_logo if bg
      end
      @backgrounds  = Background.public.all
      @backgrounds += current_site.backgrounds
      
      @backgrounds.uniq!
    end
  end

  def background_popup
    render :layout => false
  end
    
  def invoices
    @invoices = current_site.invoices.successful.paginate :page => current_page, :per_page => 15, :order => 'created_at DESC'
  end
  
  def grateful
    current_site.settings_will_change!
    current_site.settings[:ng] = (params[:value] && params[:value] == 'true') ? 1 : 0
    current_site.save!
    
    render :json => true
  end


  #
  # Payment popup
  #
  def pay
    @countries      = SmsonlineInvoice.countries_for_select
    @qiwi_options   = QiwiInvoice.options
    @robox_options  = RoboxInvoice.options

    # preferences
    @pref_method  = current_site.invoices.successful.last.try(:pref_key) || 'sms'
    @pref_sms     = SmsonlineInvoice.for_user(current_site).successful.last.try(:pref_options)
    @pref_qiwi    = QiwiInvoice.for_user(current_site).successful.last.try(:pref_options)
    @pref_robox   = RoboxInvoice.for_user(current_site).successful.last.try(:pref_options)

    render :layout => false
  end
  
  
  #
  # Billing services
  #
  def sms_update
    render :nothing => true and return false unless request.post?

    last_id   = params[:last_id].to_s || 0
    @invoices = SmsonlineInvoice.for_user(current_site).successful.all(:conditions => "invoices.id > #{last_id}")
    
    render :json => @invoices.map { |i| { :id => i.id, :summary => i.summary } }
  end
  
  def qiwi_init_bill
    render :nothing => true and return false unless request.post?
   
    phone   = params[:phone].gsub(/[^0-9]/, '')[0..10]
    user    = current_site
    option  = QiwiInvoice.options_for(params[:option])
    
    @invoice = QiwiInvoice.create!(:user      => user,
                                   :state     => 'pending',
                                   :amount    => option.amount,
                                   :revenue   => option.amount,
                                   :days      => option.days,
                                   :remote_ip => request.remote_ip,
                                   :metadata  => HashWithIndifferentAccess.new(:option => option.name,
                                                                              :protocol => 'html',
                                                                              :phone => phone
                                                                             )
                                  )
    
    render :json => @invoice.to_json
  end
  
  def robox_init_bill
    render :nothing => true and return unless request.post?
    
    option = RoboxInvoice.options_for(params[:option])
    
    @invoice = RoboxInvoice.create!(:user       => current_user,
                                    :state      => 'pending',
                                    :amount     => option.amount,
                                    :revenue    => option.amount,
                                    :days       => option.days,
                                    :remote_ip  => request.remote_ip,
                                    :metadata   => HashWithIndifferentAccess.new(:option => option.name)
                                  )
    
    redirect_to @invoice.payment_url(option)
  end
  
  protected
    def require_premium
      redirect_to user_url(current_site, settings_premium_path) unless is_premium?
    end
end