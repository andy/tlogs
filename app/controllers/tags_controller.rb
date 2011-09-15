class TagsController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_site
  
  before_filter :check_if_can_be_viewed

  helper :main
  layout 'main'


  def index
    options = { :max_rows => 100 }
    options[:include_private] = true if current_user && current_site && current_user.id == current_site.id

    obj = current_site ? current_site : Entry
    @tags = Tag.cloud(:minimum_font_size => 14, :maximum_font_size => 25) { obj.top_categories(options) }
    
    respond_to do |wants|
      wants.html { render :layout => 'tlog' }
      wants.js { render :layout => false }
    end
  end

  def view
    options = {}
    options[:include_private] = true if current_user && current_site && current_site.id == current_user.id
    options[:owner] = current_site if current_site    

    @tags = params[:tags]
    total = Entry.count_tagged_with(@tags, options) unless @tags.blank?
    @entries = (total.blank? || total <= 0) ? [] : Entry.paginate_by_category(@tags, { :total => total, :page => current_page }, options)
    # @tags_global_count = current_site ? (Entry.count_tagged_with(@tags) - total) : 0

    render :layout => 'tlog'
  end
  
  protected
    def check_if_can_be_viewed
      render :template => 'tlog/hidden', :layout => 'tlog' and return false unless current_site.can_be_viewed_by?(current_user)
    end
end
