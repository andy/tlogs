# == Schema Information
# Schema version: 20120711194752
#
# Table name: entries
#
#  id               :integer(4)      not null, primary key, indexed => [user_id, is_private], indexed => [is_mainpageable]
#  user_id          :integer(4)      default(0), not null, indexed, indexed => [is_private, created_at], indexed => [is_private, id]
#  data_part_1      :text
#  data_part_2      :text
#  data_part_3      :text
#  type             :string(0)       default("TextEntry"), not null, indexed, indexed => [is_disabled], indexed => [is_mainpageable, created_at]
#  is_disabled      :boolean(1)      default(FALSE), not null, indexed, indexed => [type]
#  created_at       :datetime        not null, indexed, indexed => [user_id, is_private], indexed => [is_mainpageable, type]
#  metadata         :text
#  comments_count   :integer(4)      default(0), not null
#  updated_at       :datetime        indexed
#  is_voteable      :boolean(1)      default(FALSE), indexed
#  is_private       :boolean(1)      default(FALSE), not null, indexed, indexed => [user_id, created_at], indexed => [user_id, id]
#  cached_tag_list  :text
#  is_mainpageable  :boolean(1)      default(TRUE), not null, indexed, indexed => [created_at, type], indexed => [id]
#  comments_enabled :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_entries_on_is_disabled                              (is_disabled)
#  index_entries_on_type                                     (type)
#  index_entries_on_is_mainpageable                          (is_mainpageable)
#  index_entries_on_user_id                                  (user_id)
#  index_entries_on_is_private                               (is_private)
#  index_entries_on_is_voteable                              (is_voteable)
#  index_entries_on_created_at                               (created_at)
#  index_entries_on_uid_pvt_cat                              (user_id,is_private,created_at)
#  index_entries_on_updated_at                               (updated_at)
#  index_entries_on_user_id_and_is_private_and_id            (user_id,is_private,id)
#  index_entries_on_type_and_is_disabled                     (type,is_disabled)
#  index_entries_on_is_mainpageable_and_created_at_and_type  (is_mainpageable,created_at,type)
#  index_entries_on_is_mainpageable_and_id                   (is_mainpageable,id)
#

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
    self.data_part_2.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s.gsub("\r", '').gsub("\n", ' ')
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
