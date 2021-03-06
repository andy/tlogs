class GlobalController < ApplicationController
  before_filter :require_current_user, :only => [:switch, :fast_forward, :relationship, :relationship_destroy, :relationship_toggle, :pref_friends]

  protect_from_forgery :only => [:switch, :fast_forward, :entry_metadata, :relationship, :relationship_destroy, :relationship_toggle, :pref_friends]

  def fast_forward
    @goto = nil

    current_user.all_friends.each do |user|
      lve = user.last_viewed_entries_count.to_i
      uec = user.entries_count_for(current_user)
      next if lve == uec

      # you can be subscribed, but not allowed to view this person entries
      next unless user.can_be_viewed_by?(current_user)

      @goto = {
          :url    => user.url,
          :fs     => user.friendship_status,
          :href   => user_url(user),
          :count  => (uec - lve).abs
        }
      break
    end

    render :json => @goto
  end

  def switch
    if request.post?
      @user = User.find_by_url(params[:url])

      redirect_to service_path(login_path) and return if @user.nil?

      redirect_to service_path(login_path) and return unless current_user.can_be_switched_to?(@user)

      session[:r] = nil
      session[:u] = @user.id
      update_cookie_sig!(@user)

      @user.log current_user, :session, "вошел в аккаунт", nil, request.remote_ip

      redirect_to service_url
    else
      @accounts = current_user.linked_accounts if current_user.can_switch?

      render :layout => false
    end
  end

  def nsfw
    if request.post?

    else
      render :layout => false
    end
  end

  def entry_metadata
    render :nothing => true and return unless request.post?

    @entry = Entry.find(params[:entry_id])
    render :text => 'oops' and return if !@entry || (@entry.is_private? && current_user && @entry.user_id != current_user.id)
    render :partial => 'tlog/metadata', :locals => { :entry => @entry }
  end

  def relationship
    render :nothing => true and return unless request.post?

    @user = User.find(params[:user_id])
    @relationship = current_user.relationship_with(@user, true)
    render :layout => false
  end

  # эта функция расчитана на вызов из globals/pref_friends, где, в случае успешного удаления, она
  #  сначала подсветит, а потом удалит выбранного пользователя из списка
  def relationship_destroy
    render :nothing => true and return unless request.post?

    @user = User.find(params[:user_id])
    render :text => 'error' and return unless user

    current_user.set_friendship_status_for(@user, Relationship::GUESSED)
  end

  # переключает статус взаимоотношений между пользователями, вызывать можно как:
  #   link_to_remote ....., url => global_url(:action => 'relationship_toggle', :user_id => user), :update => 'pref_friends_holder'
  def relationship_toggle
    render :nothing => true and return unless request.post?

    @user = User.find(params[:user_id])
    render :text => 'invalid :user_id' and return unless @user

    relationship = current_user.relationship_with(@user, true)
    # если это новая запись, либо значение где-то меньше минимального видимого - выставляем в минимальное-видимое (default)
    @friendship_status = (relationship.new_record? || relationship.friendship_status < Relationship::DEFAULT) ? Relationship::DEFAULT : Relationship::GUESSED
    relationship.update_attributes!({ :friendship_status => @friendship_status })
    relationship.position = 0
    relationship.move_to_top
    @subscribed_to = current_user.subscribed_to?(@user)
  end

  # show a friends sidebar that drop's down from the heart
  def pref_friends
    render :nothing => true and return unless request.post?

    @friends = []

    current_user.all_friends.each do |user|
      user_js = { :url => user.url, :fs => user.friendship_status, :href => user_url(user), :count => nil }

      lve = user.last_viewed_entries_count.to_i
      uec = user.entries_count_for(current_user)
      user_js[:count] = (uec - lve).abs if lve != uec
      @friends << user_js
    end

    render :json => @friends.to_json
  end

  def not_found
    render :status => 404
  end
end
