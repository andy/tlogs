class FavesController < ApplicationController
  before_filter :require_current_site, :except => [:create]
  before_filter :require_confirmed_current_site, :except => [:create, :destroy]
  before_filter :require_current_user, :only => [:create, :destroy]

  protect_from_forgery

  layout 'tlog'

  
  def index
    # fix for the faves.size < 0 problem
    faves_count = current_site.faves.size
    faves_count = current_site.faves.count if faves_count < 0
    
    @page = params[:page].to_i.reverse_page(faves_count.to_pages)
    @faves = Fave.paginate :all, :page => @page, :per_page => 15, :include => { :entry => [:attachments, :author, :rating] }, :order => 'faves.id DESC', :conditions => { :user_id => current_site.id }
  end
  
  # попадаем сюда через global/fave
  def create
    render :nothing => true and return unless request.post?

    entry = Entry.find params[:id]
    render :text => 'entry not found' and return unless entry

    fave = Fave.find_or_initialize_by_user_id_and_entry_id current_user.id, entry.id
    if fave.new_record? && !entry.is_private? && entry.user_id != current_user.id
      fave.entry_type = entry[:type]
      fave.entry_user_id = entry.user_id
      fave.save rescue nil
    end
    
    render :json => true  
  end
  
  def destroy
    entry = Entry.find params[:id]
    render :text => 'entry not found' and return unless entry

    fave = Fave.find_by_user_id_and_entry_id current_site.id, entry.id
    fave.destroy if fave && fave.is_owner?(current_user)
    
    render :update do |page|
      page.visual_effect :fade, entry.dom_id
    end
  end
end