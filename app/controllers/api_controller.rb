class ApiController < ApplicationController
  before_filter :require_current_user, :only => [:simple_auth]
  
  rescue_from ActiveRecord::RecordNotFound, :with => :api_error_not_found

  ALLOWED_API_HOSTS = %w(31.31.197.29 127.0.0.1)

  API_WHITELIST = {
    'subscribeme.ru' => '01fd09a535847a61ff5cb229',
    'tasty.zojl.ru'  => 'acc590704fe4550d4d86e8e8'
  }

  def user_details
    user   = User.active.find_by_url! params[:url] if params[:url]
    user ||= User.active.find params[:id] if params[:id]
    
    api_error(400, 'User ID or URL missing') and return unless user
    
    render :json => make_user_details(user)
  end

  def simple_auth
    api_error(400, 'Invalid argument') and return if params[:back_url].blank?
    api_error(400, 'Request missing') and return if params[:sig].blank?

    uri = URI.parse params[:back_url] rescue nil
    api_error(403, 'Access denied') and return if !uri || uri.host.blank? || !API_WHITELIST.keys.include?(uri.host)

    code = API_WHITELIST[uri.host]
    stamp = params[:stamp].to_i rescue 0

    # check that stamp is within 2 minute boundries
    api_error(403, 'Stamp timeout') and return if 60.seconds.ago.to_i > stamp || 60.seconds.from_now.to_i < stamp

    api_error(403, 'Access denied. Invalid signature.') and return if _auth_sig(code, [params[:back_url], stamp, request.remote_ip].join(':')) != params[:sig]

    stamp = Time.now.to_i

    uri.query = {
      :auth     => 1,
      :stamp    => stamp,
      :url      => current_user.url,
      :id       => current_user.id,
      :sig      => _auth_sig(code, [current_user.url, current_user.id.to_s, stamp, request.remote_ip].join(':'))
    }.to_query

    redirect_to uri.to_s
  end

  protected
    def make_user_details(user)
      Rails.cache.fetch("api:mud:#{user.id}", :expires_in => 1.hour) do
        size              = userpic_dimensions(user, :width => 32)
        userpic           = user.userpic? ? user.userpic.url(:thumb32) : nil
        subscribers_count = user.listed_me_as_all_friend_light_ids.length

        return {
          :id                => user.id,
          :url               => user.url,
          :subscribers_count => subscribers_count,
          :userpic           => userpic ? tag_helper.image_path(userpic) : nil,
          :userpic_width     => userpic ? size.width : 0,
          :userpic_height    => userpic ? size.height : 0
        }
      end
    end

    def _auth_sig(code, text)
      Digest::MD5.hexdigest([code, text].join(':'))
    end

    def api_error(code, message = 'Internal API error')
      render :json => { :status => :error, :code => code, :message => message }, :status => code
    end
    
    def api_error_not_found
      api_error(404, 'Not found')
    end

    def require_api_permissions
      api_error(403, 'Permission denied') and return false unless ALLOWED_API_HOSTS.include?(request.remote_ip)
    end
end