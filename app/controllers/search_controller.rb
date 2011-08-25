class SearchController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  
  before_filter :check_if_can_be_viewed
  
  helper :main
  layout 'main'

  def index
    if current_site && params[:limit] == 'none'
      redirect_to service_url(search_path(:query => params[:query]))
      return
    elsif !current_site && params[:user_id]
      redirect_to user_url(User.find(params[:user_id]), search_path(:query => params[:query]))
      return
    end
    
    page = (params[:page] || 1).to_i rescue 1
    page = 1 if page <= 0

    options = {
        :page           => page,
        :per_page       => Entry::PAGE_SIZE,
        :with           => {},
        :include        => :author,
        :field_weights  => { :tags => 20, :data_part_1 => 10, :data_part_2 => 5 },
        :order          => :created_at,
        :sort_mode      => :desc
      }

    if current_site
      options[:with][:user_id] = current_site.id
      if !current_user || current_user.id != current_site.id
        options[:with][:is_private] = 0
      end
    else
      options[:with][:is_private] = 0
    end

    @entries = Entry.search params[:query], options
    
    if !current_site
      user_options = {
        :page           => 1,
        :per_page       => 15,
        :field_weights  => { :url => 1, :username => 5 },
        :order          => :entries_count,
        :sort_mode      => :desc
      }
      @users = User.search params[:query], user_options
    end

    # результаты отображаются внутри тлога если поиск выполнялся по индивидуальному тлогу
    render :layout => current_site ? 'tlog' : 'main'
  end
  
  protected
    def check_if_can_be_viewed
      render :template => 'tlog/hidden', :layout => 'tlog' and return false if current_site && !current_site.can_be_viewed_by?(current_user)
    end
end
