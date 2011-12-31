class NewyearController < ApplicationController
  before_filter :require_current_user

  
  def index
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

    after  = params[:after] || {}
    result = []
    chat.channels.each { |chan| result << make_channel_recent(chan, after[chan.uuid].try(:to_i)) }
    
    render :json => result
  end
  
  protected
    def make_channel_recent(channel, after_seq = nil)
      recent = channel.recent.sort_by { |message| message[:id] }.map do |message|
        next if after_seq && message[:id] <= after_seq

        user_details = make_user_details(message[:user])
        
        {
          :id       => [channel.uuid, message[:id]].join('-'),
          :seq      => message[:id],
          :text     => message[:text],
          :iso8601  => Time.at(message[:stamp]).getutc.iso8601,
          :time     => Russian::strftime(Time.at(message[:stamp]), '%d %B %Y в %H:%M')
        }.merge(user_details)
      end.compact
      
      { :name => channel.name, :uuid => channel.uuid, :messages => recent }
    end
    
    def make_user_details(user_id)
      Rails.cache.fetch("chat:resolve:#{user_id}", :expires_in => 1.hour) do
        user = User.find(user_id)
        size = userpic_dimensions(user, :width => 32)
        
        userpic = user.userpic? ? user.userpic.url(:thumb32) : (user.avatar ? user.avatar.public_filename : nil)

        { :url => user.url, :userpic => userpic, :userpic_width => size.width, :userpic_height => size.height }
      end
    end
end