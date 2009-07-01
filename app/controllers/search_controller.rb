class SearchController < ApplicationController
  skip_before_filter :require_confirmation_on_current_user
  
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

    options = {
        :page => params[:page],
        :per_page => Entry::PAGE_SIZE,
        :with => {},
        :include => :author,
        :field_weights => { :tags => 20, :data_part_1 => 10, :data_part_2 => 5 },
        :order => :created_at,
        :sort_mode => :desc
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
    
    # результаты отображаются внутри тлога если поиск выполнялся по индивидуальному тлогу
    render :layout => current_site ? 'tlog' : 'main'
  end
end