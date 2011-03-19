class TastyradioController < ApplicationController
  
  layout 'tastyradio'
  
  def index
    @radio = User.find_by_url 'radio'
    # @archive = @radio.entries.find_tagged_with('announce', :limit => 5, :order => 'entries.id DESC')
  end
end
