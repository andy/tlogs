# = Schema Information
#
# Table name: *entries*
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      default(0), not null
#  data_part_1      :text
#  data_part_2      :text
#  data_part_3      :text
#  type             :string(255)     default(""), not null
#  is_disabled      :boolean(1)      not null
#  created_at       :datetime        not null
#  metadata         :text
#  comments_count   :integer(4)      default(0), not null
#  updated_at       :datetime
#  is_voteable      :boolean(1)
#  is_private       :boolean(1)      not null
#  cached_tag_list  :text
#  is_mainpageable  :boolean(1)      default(TRUE), not null
#  comments_enabled :boolean(1)      not null
########
#
# Текстовая запись
#   data_part_1 - текст
#   data_part_2 - заголовок
class TextEntry < Entry
  validates_presence_of :data_part_1, :on => :save
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'это поле слишком длинное'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :on => :save, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'

  def entry_russian_dict; { :who => 'ммм... пост', :whom => 'ммм... пост' } end
  def excerpt
    if self.data_part_2.to_s.length > 0 
      self.data_part_2.to_s.truncate(150).to_s
    else
      self.data_part_1.to_s.truncate(150).to_s
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
end
