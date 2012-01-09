class MentionsController < ApplicationController
  before_filter :require_current_user

  protect_from_forgery

  include ApplicationHelper
  include ActionView::Helpers::AssetTagHelper

  def in_comments
    entry_id = params[:entry_id].to_i
    users = []
    commenters = []
    @entry = Entry.find_by_id entry_id if entry_id > 0
    if @entry.can_be_viewed_by?(current_user)
      reject_author_id = @entry.user_id if @entry.is_anonymous?
      user_ids = Comment.find(:all, :conditions => "entry_id = #{entry_id}").map(&:user_id).reject { |id| id <= 0 || id == current_user.id || id == reject_author_id }.uniq
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