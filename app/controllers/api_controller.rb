require 'md5'

class ApiController < ApplicationController
  # before_filter :require_api_permissions
  before_filter :require_current_user, :require_sm_auth_code, :only => 'smauth'
  
  rescue_from ActiveRecord::RecordNotFound, :with => :api_error_not_found

  ALLOWED_API_HOSTS = %w(31.31.197.29 127.0.0.1)

  def user_details
    user   = User.active.find_by_url! params[:url] if params[:url]
    user ||= User.active.find params[:id] if params[:id]
    
    api_error(400, 'User ID or URL missing') and return unless user
    
    render :json => make_user_details(user)
  end

  def smauth
    # http://subscribeme.ru/register
    url  = params[:back_url]
    url += '?auth=1&code='+Digest::MD5.hexdigest(sm_auth_sig(params[:code], current_user.url))
    url += random_str(10)
    url += '&name='+current_user.url
    url += '&id='+current_user.id.to_s

    redirect_to url
  end

  protected
    def make_user_details(user)
      Rails.cache.fetch("api:mud:#{user.id}", :expires_in => 1.hour) do
        size              = userpic_dimensions(user, :width => 32)
        userpic           = user.userpic? ? user.userpic.url(:thumb32) : (user.avatar ? user.avatar.public_filename : nil)
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

    def sm_auth_sig(in_str, code_str)
      code_index = 0
      out_str = ''
      in_length = in_str.length-1

      for i in 0..in_length
        out_str += in_str[i].chr + code_str[code_index].chr
        code_index += 1
        code_index = 0 if code_index == code_str.length
      end

      out_str
    end

    def random_str(length)
      rand(36**length).to_s(36)
    end
    
    def api_error(code, message = 'Internal API error')
      render :json => { :status => :error, :code => code, :message => message }, :status => code
    end
    
    def api_error_not_found
      api_error(404, 'Not found')
    end

    def require_sm_auth_code
      render :text => '' if !params[:code]
    end

    def require_api_permissions
      api_error(403, 'Permission denied') and return false unless ALLOWED_API_HOSTS.include?(request.remote_ip)
    end
end