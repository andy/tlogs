class Settings::MobileController < ApplicationController
  before_filter :require_current_user, :require_owner
  before_filter :require_confirmed_current_user

  protect_from_forgery

  helper :settings
  layout "settings"

  def email
    # create mobile settings thing
    current_site.mobile_settings ||= MobileSettings.create :user => current_site, :keyword => MobileSettings.generate_keyword

    # update mobile settings if post request
    current_site.mobile_settings.update_attributes(:keyword => MobileSettings.generate_keyword) if request.post?

    # used in views
    @private_email = "post+#{current_site.mobile_settings.keyword}@#{current_service.domain}"

    respond_to do |wants|
      wants.html # email.rhtml
      wants.js do
        render :update do |page|
          page.replace_html :private_email, @private_email
          page.visual_effect :highlight, :private_email, { :duration => 0.3 }
        end
      end
    end
  end

  def bookmarklets
    @bookmarklet = Bookmarklet.find_by_id_and_user_id(params[:id], current_site.id) if params[:id]
    @bookmarklet ||= Bookmarklet.new

    if request.post?
      @bookmarklet.attributes = params[:bookmarklet]
      @bookmarklet.user = current_site
      if @bookmarklet.save
        flash[:good] = 'Закладка была сохранена'
        redirect_to :action => :bookmarklets, :id => nil
      else
        flash[:bad] = 'Не сохранили закладку из-за ошибки'
      end
    end
  end

  def bookmarklet_destroy
    @bookmarklet = Bookmarklet.find_by_id_and_user_id(params[:id], current_site.id)
    @bookmarklet.destroy if @bookmarklet
  end
end
