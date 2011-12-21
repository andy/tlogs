class MentionsController < ApplicationController
  before_filter :require_current_user

  protect_from_forgery

  include ApplicationHelper
  include ActionView::Helpers::AssetTagHelper

  def in_comments
    entry_id = params[:entry_id].to_i
    users = []
    all_users = []
    if entry_id > 0
      user_ids  = Comment.find(:all, :conditions => "entry_id = #{entry_id}").map(&:user_id).reject { |id| id <= 0 || id == current_user.id }.uniq
      all_users += User.find(user_ids).reject { |u| !u.email_comments? } if user_ids.any?
      all_users += current_user.public_friends+current_user.friends
      if all_users
        exclude_ids = []
        added_ids = []
        all_users.each do |u|
          if !exclude_ids.include?(u.id)
            users.push({ 'pic' => userpic_src(u, { :style => :thumb16 }), 'url' => u.url }) 
            added_ids.push(u.id)
          end
          exclude_ids.push(u.id) if added_ids.include?(u.id)
        end
      end
    end
    render :json => { 'success' => true, 'list' => users }
  end
end