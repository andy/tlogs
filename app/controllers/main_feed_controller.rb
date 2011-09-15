class MainFeedController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  layout nil
  caches_action :live, :last, :photos, :cache_path => Proc.new { |c| c.url_for(:expiring => (Time.now.to_i / 1.minute).to_i, :page => c.params[:page]) }

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

    @filter = Struct.new(:kind, :rating).new(kind, rating)
    @entry_ratings = EntryRating.find :all, :include => { :entry => [:attachments, :author]}, :limit => 15, :order => 'entry_ratings.id DESC', :conditions => "#{EntryRating::RATINGS[@filter.rating.to_sym][:filter]} AND #{Entry::KINDS[@filter.kind.to_sym][:filter]}"
    @entries = @entry_ratings.map { |er| er.entry }

    response.headers['Content-Type'] = 'application/rss+xml'
  end
  
  def live
    sql_conditions = 'entries.is_mainpageable = 1'

    if params[:entry_id]
      entry_ids = Entry.find(:all, :select => 'entries.id', :conditions => [sql_conditions, " entries.id < #{params[:entry_id].to_i}"].join(' AND '), :order => 'entries.id DESC', :limit => Entry::PAGE_SIZE).map(&:id)
      result = Entry.find_all_by_id(entry_ids, :include => [:author, :rating, :attachments]).sort_by { |entry| entry_ids.index(entry.id) }
      
      @entries = result
    else
      @entries = Entry.find :all, :conditions => sql_conditions, :order => 'entries.id DESC', :include => [:author, :attachments], :limit => 15
    end

    response.headers['Content-Type'] = 'application/rss+xml'
    render :action => 'last'
  end
  
  def photos
    @entries = Entry.find :all, :conditions => "entries.is_private = 0 AND entries.is_mainpageable = 1 AND entries.type = 'ImageEntry'", :page => { :current => current_page, :size => 50, :count => ((current_page + 1) * 50) }, :order => 'entries.id DESC', :include => [:author, :attachments]

    response.headers['Content-Type'] = 'application/rss+xml'
    render :template => 'tlog_feed/media'
  end
end
