class ApiController < ApplicationController
  # before_filter :require_api_permissions

  ALLOWED_API_HOSTS = %w(92.38.229.197 127.0.0.1)

  helper :userpic


  def user_details
    render :json => make_user_details(params[:url])
  end

  protected
    def make_user_details(url)
      Rails.cache.fetch("api:mud:#{url}", :expires_in => 1.hour) do
        user = User.find_by_url(url) || raise(ActiveRecord::RecordNotFound)
        size = userpic_dimensions(user, :width => 32)
        
        userpic = user.userpic? ? user.userpic.url(:thumb32) : (user.avatar ? user.avatar.public_filename : nil)

        subscribers_count = user.listed_me_as_all_friend_light_ids.length

        return {
          :url               => user.url,
          :subscribers_count => subscribers_count,
          :userpic           => userpic ? userpic : 0,
          :userpic_width     => userpic ? size.width : 0,
          :userpic_height    => userpic ? size.height : 0
        }
      end
    end

    def require_api_permissions
      render :nothing => true and return false unless ALLOWED_API_HOSTS.include?(request.remote_ip)
    end
end