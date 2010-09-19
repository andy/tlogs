# = Schema Information
#
# Table name: *entry_ratings*
#
#  id         :integer(4)      not null, primary key
#  entry_id   :integer(4)      default(0), not null
#  entry_type :string(20)      default(""), not null
#  created_at :datetime        not null
#  user_id    :integer(4)      default(0), not null
#  value      :integer(4)      default(0), not null
########
class EntryRating < ActiveRecord::Base
  belongs_to :entry
  
  RATINGS = {
    :great => { :select => 'Великолепное (+5 и круче)', :header => 'Самое прекрасное!!!@#$%!', :filter => 'entry_ratings.is_great = 1', :order => 1 },
    :good => { :select => 'Интересное (+2 и выше)', :header => 'Интересное на тейсти', :filter => 'entry_ratings.is_good = 1', :order => 2 },
    :everything => { :select => 'Всё подряд (-5 и больше)', :header => 'Всё подряд на тейсти', :filter => 'entry_ratings.is_everything = 1', :order => 3 }
  }
  RATINGS_FOR_SELECT = RATINGS.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:select], k.to_s] }

  validates_presence_of :user_id
  validates_presence_of :entry_id
  validates_presence_of :entry_type
  
  before_save :update_filter_value
  
  protected
    def update_filter_value
      self.is_great       = self.value >= 15
      self.is_good        = self.value >= 5
      self.is_everything  = self.value >= -5
    end
end
