class MentionsController < ApplicationController
  before_filter :require_current_user

  protect_from_forgery

  include ApplicationHelper
  include ActionView::Helpers::AssetTagHelper

  def in_comments
    entry_id = params[:entry_id].to_i
    users = []
    commenters = []
    if entry_id > 0
      user_ids  = Comment.find(:all, :conditions => "entry_id = #{entry_id}").map(&:user_id).reject { |id| id <= 0 || id == current_user.id }.uniq
      commenters += User.find(user_ids).reject { |u| !u.email_comments? } if user_ids.any?
      if commenters
        commenters.each do |u| 
          users.push({ 'pic' => userpic_src(u, { :style => :thumb16 }), 'url' => u.url }) 
        end
      end
    end
    render :json => { 'success' => true, 'list' => users }
  end
end