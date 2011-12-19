class MentionsController < ApplicationController
  before_filter :require_current_user
  
  protect_from_forgery

  def mentions
    entry_id = params[:entry_id].to_i
    users = []
    all_users = []
    if entry_id > 0
      user_ids  = Comment.find(:all, :conditions => "entry_id = #{entry_id}").map(&:user_id).reject { |id| id <= 0 || id == current_user.id }.uniq
      all_users += User.find(user_ids).reject { |u| !u.email_comments? } if user_ids.any?
      all_users += current_user.public_friends+current_user.friends
      if all_users
        all_users.each do |u|
          if !user_ids.include?(u.id)
            pic = 0
            pic = u.userpic_file_name if u.userpic_file_name
            users.push({ 'pic' => pic, 'url' => u.url })
          else
            user_ids.pop(u.id)
          end
        end
      end
    end
    render :json => { 'success' => true, 'list' => users }
  end
end