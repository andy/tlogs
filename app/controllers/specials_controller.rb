class SpecialsController < ApplicationController

  def index
    redirect_to '/'
  end

  def darudar

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
end
