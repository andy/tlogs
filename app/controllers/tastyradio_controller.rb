class TastyradioController < ApplicationController
  before_filter :preload_radio

  before_filter :require_current_user, :except => [:index]
  before_filter :require_radio_dj, :except => [:index]

  helper :main
  layout 'main'


  def index    
    render :layout => 'tastyradio'
  end
  
  def all
    @radio_schedules = RadioSchedule.all.paginate :page => params[:page], :per_page => 2
  end
  
  def create
    @radio_schedule       = RadioSchedule.new params[:radio_schedule]
    @radio_schedule.user  = current_user
    if @radio_schedule.save
      flash[:good] = 'Новая передача была добавлена в эфир'

      redirect_to :action => 'all'
    else
      errors = []
      errors << "продолжительность была указана неверно" if @radio_schedule.errors.invalid?(:end_at)
      errors << @radio_schedule.errors.on(:body) if @radio_schedule.errors.invalid?(:body)
      
      flash[:bad] = "Не получилось добавить передачу: #{errors.join(", ")}"
    end
  end
  
  def destroy
    @radio_schedule = RadioSchedule.find params[:id]
    @radio_schedule.destroy if @radio_schedule.is_owner?(current_user)
  end

  protected
    def require_radio_dj
      render :text => 'ur not a radio dj', :status => 403 and return false unless RadioSchedule.djs.include?(current_user.id)
    end
    
    def preload_radio
      @radio = User.find_by_url('radio')
    end
end
