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
      self.data_part_2.to_s.truncate(150).to_s
    elsif self.data_part_3.to_s.length > 0
      self.data_part_3.to_s.truncate(150).to_s
    else
      'Ссылка'
    end
  end
  
  def self.new_from_bm(params)
    self.new :data_part_1 => params[:url], :data_part_2 => params[:title], :data_part_3 => params[:c]
  end
  
  before_validation :make_a_link_from_data_part_1_if_present
end