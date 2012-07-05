# == Schema Information
# Schema version: 20110816190509
#
# Table name: entries
#
#  id               :integer(4)      not null, primary key, indexed => [is_mainpageable]
#  user_id          :integer(4)      default(0), not null, indexed, indexed => [is_private, created_at]
#  data_part_1      :text
#  data_part_2      :text
#  data_part_3      :text
#  type             :string(0)       default("TextEntry"), not null, indexed
#  is_disabled      :boolean(1)      default(FALSE), not null, indexed
#  created_at       :datetime        not null, indexed, indexed => [user_id, is_private]
#  metadata         :text
#  comments_count   :integer(4)      default(0), not null
#  updated_at       :datetime
#  is_voteable      :boolean(1)      default(FALSE), indexed
#  is_private       :boolean(1)      default(FALSE), not null, indexed, indexed => [user_id, created_at]
#  cached_tag_list  :text
#  is_mainpageable  :boolean(1)      default(TRUE), not null, indexed, indexed => [id]
#  comments_enabled :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_entries_on_is_disabled             (is_disabled)
#  index_entries_on_type                    (type)
#  index_entries_on_is_mainpageable         (is_mainpageable)
#  index_entries_on_user_id                 (user_id)
#  index_entries_on_is_private              (is_private)
#  index_entries_on_is_voteable             (is_voteable)
#  index_entries_on_created_at              (created_at)
#  index_entries_on_uid_pvt_cat             (user_id,is_private,created_at)
#  index_entries_on_is_mainpageable_and_id  (is_mainpageable,id)
#

class ConvoEntry < Entry
  validates_presence_of :data_part_1, :message => 'это обязательное поле'
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'ммм... слишком длинный диалог'
  validates_length_of :data_part_2, :within => 0..ENTRY_MAX_LENGTH, :on => :save, :if => Proc.new { |e| !e.data_part_2.blank? }, :too_long => 'это поле слишком длинное'
  def entry_russian_dict; { :who => 'диалог', :whom => 'диалог' } end
  
  def excerpt
    self.data_part_1.to_s.gsub(/<object.*?<\/object>/i, ' ').truncate(150).to_s
  end
  def self.new_from_bm(params)
    self.new :data_part_1 => params[:c], :data_part_2 => params[:title]
  end
end
