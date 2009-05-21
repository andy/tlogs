class ConvoEntry < Entry
  validates_presence_of :data_part_1, :message => 'это обязательное поле'
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'ммм... слишком длинный диалог'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :on => :save, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'
  def entry_russian_dict; { :who => 'диалог', :whom => 'диалог' } end
  
  def excerpt
    self.data_part_1.to_s.truncate(150).to_s
  end
  def self.new_from_bm(params)
    self.new :data_part_1 => params[:c], :data_part_2 => params[:title]
  end
end