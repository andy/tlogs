class MentionsController < ApplicationController
  before_filter :require_current_user
  
  protect_from_forgery

  def mentions
    entry_id = params[:entry_id].to_i
    users = []
    all_users = current_user.public_friends+current_user.friends
    if entry_id > 0
      user_ids  = Comment.find(:all, :conditions => "entry_id = #{entry_id}").map(&:user_id).reject { |id| id <= 0 }.uniq
      all_users += User.find(user_ids).reject { |u| !u.email_comments? } if user_ids.any?
      if all_users
        all_users.each do |u|
          pic = 0
          pic = u.userpic_file_name if u.userpic_file_name
          users.push({ 'pic' => pic, 'url' => u.url })
        end
      end
    end
    render :json => { 'success' => true, 'list' => users }
  end
end