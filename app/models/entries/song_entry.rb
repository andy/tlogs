# Песня
class SongEntry < Entry
  validates_presence_of :data_part_1, :if => :no_attachment, :message => 'это обязательное поле'
  validates_format_of :data_part_1, :with => Format::HTTP_LINK, :if => :no_attachment, :message => 'ссылка должна быть на веб-сайт, т.е. начинаться с http://'
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LINK_LENGTH, :if => :no_attachment, :too_long => 'ссылка какая-то очень длинная'  
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'

  def entry_russian_dict; { :who => 'песня', :whom => 'песню' } end
  def can_have_attachments?; true; end
  
  def excerpt
    self.data_part_2.to_s.truncate(150).to_s
  end

  before_validation :make_a_link_from_data_part_1_if_present
end