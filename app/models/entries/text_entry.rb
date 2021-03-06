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
# Текстовая запись
#   data_part_1 - текст
#   data_part_2 - заголовок
class TextEntry < Entry
  validates_presence_of :data_part_1, :on => :save
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'это поле слишком длинное', :too_short => 'это поле не может быть пустым'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :on => :save, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'

  def entry_russian_dict; { :who => 'ммм... пост', :whom => 'ммм... пост' } end
  def excerpt
    if self.data_part_2.to_s.length > 0
      self.data_part_2.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s.gsub("\r", '').gsub("\n", ' ')
    else
      self.data_part_1.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s.gsub("\r", '').gsub("\n", ' ')
    end
  end
  def self.new_from_bm(params)
    content = params[:c].strip if params[:c]
    content ||= ''
    title = params[:title].strip if params[:title]
    # разбиваем на две новые части если нет заголовка, но есть содержимое
    title, content = content.split("\n", 2) if title.blank? && !content.blank?
    title = title.truncate(50) if title
    content += "\n<a href='#{params[:url]}'>отсюда</a>" if content
    self.new :data_part_1 => content, :data_part_2 => title
  end

  def title
    excerpt
  end
end
