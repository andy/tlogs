# = Schema Information
#
# Table name: *bookmarklets*
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)      not null
#  created_at :datetime        not null
#  name       :string(255)     not null
#  entry_type :string(16)      default("text"), not null
#  tags       :text
#  visibility :string(16)      default("private"), not null
#  autosave   :boolean(1)      not null
#  is_public  :boolean(1)      not null
########
class Bookmarklet < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
  validates_length_of :name, :within => 1..200
  validates_inclusion_of :entry_type, :in => Entry::KINDS_FOR_SELECT_SIGNULAR.map { |v| v[1] }.reject { |v| %w(song).include?(v) }
  validates_inclusion_of :visibility, :in => Entry::VISIBILITY_FOR_SELECT_NEW.map { |v| v[1] }

  attr_protected :user_id

  def is_owner?(user)
    user.id == self.user_id
  end
end
