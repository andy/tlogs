class ApiController < ApplicationController

  include ApplicationHelper
  include ActionView::Helpers::AssetTagHelper

  # error codes
  # 1 - неправильный ключ
  # 2 - передан несуществующий метод

  # ключ subscribe me
  # md5(92.38.229.197) = 7affe8c8390109795c4793ec2a2571b3

  def index
    error = 0
    error_descr = ''
    result = []
    if params[:k] == '7affe8c8390109795c4793ec2a2571b3'
      case params[:m]
        when 'make_user_details'
          if !params[:u]
            error = 3
            error_descr = 'bad username'
          else
            result = make_user_details(params[:u])
            if !result
              result = []
              error = 4
              error_descr = 'username not found'
            end
          end

        else
          error = 2
          error_descr = 'bad method name'
      end
    else
      error = 1
      error_descr = 'bad key'
    end

    render :json => { :error => error, :error_descr => error_descr, :result => result }
  end

  private
    def make_user_details(user_name)
      Rails.cache.fetch("subscribeme:resolve:#{user_name}", :expires_in => 3.hour) do
        user = User.find_by_url(user_name)
        return false if !user 
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
end