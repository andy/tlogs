class VoteController < ApplicationController
  before_filter :require_current_user, :require_confirmed_current_user, :require_voteable_entry_id
  
  protect_from_forgery

  def up; vote(1) end
  def down; vote(-1) end
  
  private
    def vote(rating)
      @entry.vote(current_user, rating)
      
      render :json => @entry.rating.try(:value) || 0
    end

    def require_voteable_entry_id
      @entry = Entry.find(params[:entry_id]) rescue nil
      render(:text => 'sorry, entry not found') and return false unless @entry
      render(:text => 'sorry, post requests only') and return false unless request.post?
      render(:text => 'sorry, entry is not voteable') and return false unless @entry.is_voteable?
      render(:text => 'sorry, you cant vote for this entry') and return false unless current_user.can_vote?(@entry)
      true
    end
end