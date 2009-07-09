class ActivitiesController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :require_confirmed_current_site
  
  layout 'tlog'
  
  def index
    @results = ThinkingSphinx::Search.search(:with => { :watcher_ids => [current_user.id] }, :order => 'created_at DESC', :page => params[:page], :per_page => 30)
  end
end