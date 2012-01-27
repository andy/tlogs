class ApiController < ApplicationController
  # before_filter :require_api_permissions
  
  rescue_from ActiveRecord::RecordNotFound, :with => :api_error_not_found

  ALLOWED_API_HOSTS = %w(92.38.229.197 127.0.0.1)


  def user_details
    user   = User.active.find_by_url! params[:url] if params[:url]
    user ||= User.active.find params[:id] if params[:id]
    
    api_error(400, 'User ID or URL missing') and return unless user
    
    render :json => make_user_details(user)
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