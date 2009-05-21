# Встроенное видео, вроде youtube
#   data_part_1 - link / embed код
#   data_part_2 - описание
class VideoEntry < Entry
  validates_presence_of :data_part_1, :message => 'это обязательное поле'
#  validates_format_of :data_part_1, :with => Format::HTTP_LINK, :message => 'ссылка должна быть на веб-сайт, т.е. начинаться с http://'  
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'ммм... код какой-то слишком длинный'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :on => :save, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'
  def entry_russian_dict; { :who => 'видео', :whom => 'видео' } end
  
  before_validation :make_a_link_from_data_part_1_if_present
  
  def excerpt
    self.data_part_2.to_s.truncate(150).to_s
  end
  
  def self.new_from_bm(params)
    if params[:c] && params[:c].downcase.starts_with?('<object')
      embed_or_url = params[:c]
      desc = "<a href='#{params[:url]}'>#{params[:title] || params[:url]}</a>"
    else
      embed_or_url = params[:url]
      desc = params[:c] || params[:title]
    end
    self.new :data_part_1 => embed_or_url, :data_part_2 => desc
  end
  
  # пытаемся подключить видео формат после того как видео было найдено
  # def after_find
  #   self.metadata = {} if self.metadata.nil?
  #   if self.metadata[:video_module].blank?
  #     self.metadata[:video_module] = Video::detect_by_link(self.data_part_1)
  #     self.metadata_will_change!
  #   end
  #   self.extend self.metadata[:video_module].blank? ? Video::Unknown : self.metadata[:video_module].constantize
  # end
  
  # def data_part_1=(link)
  #   write_attribute(:data_part_1, link)
  #   unless link.blank?
  #     self.metadata = {} if self.metadata.nil?      
  #     self.metadata[:video_module] = Video::detect_by_link(link)
  #     self.metadata_will_change!
  #     self.extend metadata[:video_module].blank? ? Video::Unknown : metadata[:video_module].constantize
  #   end
  # end
end
