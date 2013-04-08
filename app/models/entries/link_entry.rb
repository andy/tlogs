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

#
# Cсылка куда-либо
#   data_part_1 - адрес ссылки (обяз)
#   data_part_2 - заголовок для ссылки
#   data_part_3 - дополнительное описание
class LinkEntry < Entry
  validates_presence_of :data_part_1, :on => :save, :message => 'это обязательное поле'
  validates_format_of :data_part_1, :with => Format::LINK, :message => 'неопознанный формат ссылки'
  validates_length_of :data_part_1, :within => 0..ENTRY_MAX_LINK_LENGTH, :too_long => 'ссылка какая-то очень длинная'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'
  validates_length_of :data_part_3, :within => 0..ENTRY_MAX_LENGTH, :if => Proc.new { |e| !e.data_part_3.blank? }, :too_long => 'это поле слишком длинное'

  def entry_russian_dict; { :who => 'ссылка', :whom => 'ссылку' } end
  def excerpt
    if self.data_part_2.to_s.length > 0
      self.data_part_2.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s.gsub("\r", '').gsub("\n", ' ')
    elsif self.data_part_3.to_s.length > 0
      self.data_part_3.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s.gsub("\r", '').gsub("\n", ' ')
    else
      'Ссылка'
    end
  end
  
  def title
    excerpt
  end
  
  def self.new_from_bm(params)
    self.new :data_part_1 => params[:url], :data_part_2 => params[:title], :data_part_3 => params[:c]
  end
  
  before_validation :make_a_link_from_data_part_1_if_present
end
