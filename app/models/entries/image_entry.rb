#
# Залитая фотография либо ссылка на фото
#   data_part_1 - ссылка, если нет аттачмента
#   data_part_2 - описание
#   data_part_3 - ссылка под фотографией
class ImageEntry < Entry
  validates_presence_of :data_part_1, :on => :save, :if => :no_attachment, :message => 'это обязательное поле'
  validates_format_of :data_part_1, :with => Format::HTTP_LINK, :if => :no_attachment, :message => 'ссылка должна быть на веб-сайт, т.е. начинаться с http://'
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LINK_LENGTH, :if => :no_attachment, :too_long => 'ссылка какая-то очень длинная'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'
  validates_length_of :data_part_3, :within => 0..ENTRY_MAX_LINK_LENGTH, :if => Proc.new { |e| !e.data_part_3.blank? }, :too_long => 'ссылка какая-то очень длинная'
  validates_format_of :data_part_3, :with => Format::HTTP_LINK, :if => Proc.new { |e| !e.data_part_3.blank? }, :message => 'ссылка должна быть на веб-сайт, т.е. начинаться с http://'

  def entry_russian_dict; { :who => 'картинка', :whom => 'картинку' } end
  def can_have_attachments?; true end

  before_validation :make_a_link_from_data_part_1_if_present
  def excerpt
    if self.data_part_2.to_s.length > 0
      self.data_part_2.to_s.truncate(150).to_s
    else
      'Картинка'
    end
  end
  
  def self.new_from_bm(params)
    url = params[:url]
    uri = URI.parse(url)
    source = url if uri.path && %w(.jpg .jpeg .gif .png .bmp).include?(File.extname(uri.path.downcase))
    content = params[:c]
    # если фликер - спец обработчик
    if uri.host && uri.path && uri.host.ends_with?('flickr.com')

      # согласно http://www.flickr.com/services/api/misc.urls.html      
      photo_id = if uri.host.ends_with?('.static.flickr.com')
                  # статический путь до картинки - http://farm1.static.flickr.com/81/248825450_1140cb041a.jpg?v=0
                  uri.path.match(/^\/[0-9]*\/([0-9]*)/i)[1]
                elsif uri.host == 'www.flickr.com' && uri.path =~ /^\/photos\/[^\/]*\/([0-9]*)/i
                  # дали путь до html файла с картинкой, photo_id = $1
                  # http://www.flickr.com/photos/caballero/248825450/in/photostream/
                  $1
                end
      if photo_id
        require 'flickr'

        photo = Flickr::Photo.new photo_id
        source = photo.source
        url = photo.url
        content ||= ["<b>#{photo.title}</b>", photo.description].join("\n")
      end
    end
    self.new :data_part_1 => source, :data_part_2 => content, :data_part_3 => url
  end
  
  
  def data_part_1=(link)
    write_attribute(:data_part_1, link)
    
    if link =~ Format::HTTP_LINK
      self.metadata_will_change!
      self.metadata = {} if self.metadata.nil?
      self.metadata.merge!(get_metadata_for_linked_image(link))
    end
  end
  
  # функция вычисления симметричных размеров для текущей картинки. работает как для записей
  # с локальной картинкой, так и для записей только со ссылкой на картинку.
  def geometry(options = {})
    width = options[:width] || 420
    height = options[:height] || 0
    image = options[:image]
    image ||= self.attachments.first if self.attachments
    
    if image
      image_width, image_height = self.attachments.first.width, self.attachments.first.height
    elsif self.metadata && self.metadata.has_key?(:width)
      image_width, image_height = self.metadata[:width], self.metadata[:height]
    else
      return { }
    end

    w_ratio = width > 0 ? width.to_f / image_width.to_f : 1
    h_ratio = height > 0 ? height.to_f / image_height.to_f : 1

    ratio = [w_ratio, h_ratio].min
    
    # пересчитываем
    width = ratio < 1 ? (image_width * ratio).to_i : image_width
    height = ratio < 1 ? (image_height * ratio).to_i : image_height

    { :width => width, :height => height }
  end

  private
    def get_metadata_for_linked_image(link)
      Rails.cache.fetch("remote_image_#{Digest::SHA1.hexdigest(link)}", :expires_in => 15.minutes) do
        image_attributes = { }
        Tempfile.open("remote_image", File.join(RAILS_ROOT, 'tmp')) do |tempfile|
          tempfile.write Net::HTTP.get(URI.parse(link))
          image_attributes = ImageScience.with_image(tempfile.path) { |image| { :width => image.width, :height => image.height } }
        end
        image_attributes
      end || { }
    rescue
      logger.debug "could not get image metadata for this url: #{link}"
      { }
    end
end