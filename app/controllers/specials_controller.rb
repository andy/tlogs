class SpecialsController < ApplicationController
  
  def index
    redirect_to '/'
  end

  def surfingbird
    @title = "Surfingbird — мы подбираем интересные страницы, фото и видео на основе рекомендаций людей, которым нравится то же, что и тебе."

    sb_config = YAML.load_file(File.join(Rails.root, 'config/specials/surfingbird.yml')).symbolize_keys!
    
    # pick random set
    offset = rand(sb_config[:sets].length)
    
    @items = []
    sb_config[:sets][offset].each do |item|
      @items << OpenStruct.new(:url    => item['url'],
                                :title  => item['title'],
                                :image  => "/images/specials/surfingbird/#{item['image'] || File.basename(item['url'])}.png"
                              )
    end unless sb_config[:sets].length.zero?
    
    render :layout => false
  end
  
  def newyear
    @title = "Forever Alone Tasty New Year"
    
    @addr  = Ipgeobase.lookup(request.remote_ip)
    @city  = @addr[:city] if @addr && @addr[:city]
    
    @autojoin = ['Прямой эфир', @city].compact
  end
  
  def join
    chat = TastyChat.for(:user => current_user, :redis => $redis)
    chan = chat.channel params[:name]
    chan.subscribe!

    render :json => [make_channel_recent(chan)]
  end
  
  def leave
    chat = TastyChat.for(:user => current_user, :redis => $redis)
    chan = chat.channel params[:name]
    chan.unsubscribe!
    
    render :json => { :name => chan.name, :uuid => chan.uuid }
  end
  
  def post
    chat = TastyChat.for(:user => current_user, :redis => $redis)
    chan = chat.channel params[:name]
    
    chan.post params[:text]
    
    render :json => true
  end
  
  def read
    chat = TastyChat.for(:user => current_user, :redis => $redis)

    result = []
    chat.channels.each { |chan| result << make_channel_recent(chan) }
    
    render :json => result
  end
  
  protected
    def make_channel_recent(channel)
      recent = channel.recent.sort_by { |message| message[:id] }.map do |message|
        # cache user details
        user_details = Rails.cache.fetch("chat:resolve:#{message[:user]}", :expires_in => 1.hour) do
          user    = User.find(message[:user])
          userpic = user.userpic? ? user.userpic.url : (user.avatar ? user.avatar.public_filename : nil)

          { :url => user.url, :userpic => userpic }
        end
        
        # result
        {
          :id       => [channel.uuid, message[:id]].join('-'),
          :text     => message[:text],
          :iso8601  => Time.at(message[:stamp]).getutc.iso8601,
          :time     => Russian::strftime(Time.at(message[:stamp]), '%d %B %Y в %H:%M'),
          :url      => user_details[:url],
          :userpic  => user_details[:userpic]
        }
      end
      
      { :name => channel.name, :uuid => channel.uuid, :messages => recent }
    end
end