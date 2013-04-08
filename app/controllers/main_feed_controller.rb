class MainFeedController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  layout nil
  caches_action :live, :last, :cache_path => Proc.new { |c| c.url_for(:expiring => (Time.now.to_i / 1.minute).to_i, :page => c.params[:page]) }, :expires_in => 1.minute

  def last
    ### такая же штука определена в main_controller.rb

    # подгружаем
    kind = params[:kind] || 'default'
    rating = params[:rating] || 'default'  
    
    # выставляем значения по-умолчанию
    kind = 'any' if kind == 'default'
    rating = 'good' if rating == 'default'
  
    kind = 'any' unless Entry::KINDS.include?(kind.to_sym)
    rating = 'good' unless EntryRating::RATINGS.include?(rating.to_sym)

    @filter   = Struct.new(:kind, :rating).new(kind, rating)
    
    qkey      = [rating, kind == 'any' ? nil : "#{kind}_entry"].compact.join(':')
    entry_ids = EntryQueue.new(qkey).page(current_page)

    @entries  = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }

    response.headers['Content-Type'] = 'application/rss+xml'
  end
  
  def live
    queue       = EntryQueue.new('live')
    entry_id    = params[:page].to_i if params[:page]
    entry_ids   = (entry_id && entry_id > 0) ? queue.after(entry_id) : queue.page(1)
    
    @entries = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
    
    response.headers['Content-Type'] = 'application/rss+xml'
    render :action => 'last'
  end
  
  # def photos
  #   entry_ids = EntryQueue.new('good:image_entry').page(current_page)
  #   
  #   @entries = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, { :attachments => :thumbnails }]).sort_by { |entry| entry_ids.index(entry.id) }
  # 
  #   response.headers['Content-Type'] = 'application/rss+xml'
  #   render :template => 'tlog_feed/media'
  # end
end
