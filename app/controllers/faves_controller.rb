class FavesController < ApplicationController
  before_filter :require_current_site, :except => [:create]
  before_filter :require_confirmed_current_site, :except => [:create, :destroy]
  before_filter :require_current_user, :only => [:create, :destroy]
  
  before_filter :enable_shortcut, :only => [:index]

  before_filter :check_if_can_be_viewed

  protect_from_forgery

  layout 'tlog'

  
  def index
    # fix for the faves.size < 0 problem
    faves_count = current_site.faves.size
    faves_count = current_site.faves.count if faves_count < 0
    
    @pager        = current_site.faves.paginate(:all, :page => current_page, :per_page => 15, :select => 'entry_id', :order => 'faves.id DESC')
    entry_ids     = @pager.map(&:entry_id)

    entry_ids_key = Digest::SHA1.hexdigest(entry_ids.join(','))[0..8]

    @cache_key    = ['tlog', 'faves', current_service.domain, current_site.id, current_site.url, current_page, is_owner?, current_site.entries_updated_at.to_i, entry_ids_key].join(':')
    Rails.logger.debug "* cache key is #{@cache_key}"
    
    @entries      = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) } unless Rails.cache.exist? "views/#{@cache_key}"
    
    # @entries.reject! { |entry| current_user.blacklist_ids.include?(entry.user_id) } if current_user && current_user.is_premium?
    
    @comment_views = User::entries_with_views_for(entry_ids, current_user)
    
    render :layout => false if request.xhr?
  end
  
  # попадаем сюда через global/fave
  def create
    render :nothing => true and return unless request.post?

    entry = Entry.find params[:id]
    render :text => 'entry not found' and return unless entry

    Fave.transaction do
      fave = Fave.find_or_initialize_by_user_id_and_entry_id current_user.id, entry.id
      if fave.new_record? && !entry.is_private? && entry.user_id != current_user.id
        fave.entry_type = entry[:type]
        fave.entry_user_id = entry.user_id
        fave.save rescue nil
      end
    end
    
    render :json => true  
  end
  
  def destroy
    entry = Entry.find params[:id]
    render :text => 'entry not found' and return unless entry

    Fave.transaction do
      fave = Fave.find_by_user_id_and_entry_id current_site.id, entry.id
      fave.destroy if fave && fave.is_owner?(current_user)
    end
    
    render :update do |page|
      page.visual_effect :fade, entry.dom_id
    end
  end
  
  protected
    def check_if_can_be_viewed
      render :template => 'tlog/hidden' and return false if current_site && !current_site.can_be_viewed_by?(current_user)
    end
    
end