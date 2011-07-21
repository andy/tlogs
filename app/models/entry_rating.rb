# == Schema Information
# Schema version: 20110223155201
#
# Table name: entry_ratings
#
#  id            :integer(4)      not null, primary key
#  entry_id      :integer(4)      default(0), not null
#  entry_type    :string(0)       default("TextEntry"), not null
#  created_at    :datetime        not null
#  user_id       :integer(4)      default(0), not null
#  value         :integer(4)      default(0), not null
#  is_great      :boolean(1)      default(FALSE), not null
#  is_good       :boolean(1)      default(FALSE), not null
#  is_everything :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_entry_ratings_on_entry_id                 (entry_id) UNIQUE
#  index_entry_ratings_on_value_and_entry_type     (value,entry_type)
#  index_entry_ratings_on_entry_type               (entry_type)
#  index_entry_ratings_on_is_great                 (is_great)
#  index_entry_ratings_on_is_good                  (is_good)
#  index_entry_ratings_on_is_everything            (is_everything)
#  index_entry_ratings_on_is_great_and_entry_type  (is_great,entry_type)
#

class EntryRating < ActiveRecord::Base
  belongs_to :entry
  
  DAY_LIMIT = 7000.0
  
  RATINGS = {
    :great => { :select => 'Великолепное (+15 и круче)', :header => 'Самое прекрасное!!!@#$%!', :filter => 'entry_ratings.is_great = 1', :order => 1 },
    :good => { :select => 'Интересное (+5 и выше)', :header => 'Интересное на тейсти', :filter => 'entry_ratings.is_good = 1', :order => 2 },
    :everything => { :select => 'Всё подряд (-5 и больше)', :header => 'Всё подряд на тейсти', :filter => 'entry_ratings.is_everything = 1', :order => 3 }
  }
  RATINGS_FOR_SELECT = RATINGS.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:select], k.to_s] }

  validates_presence_of :user_id
  validates_presence_of :entry_id
  validates_presence_of :entry_type
  
  before_save :update_filter_value
  
  before_save :update_hotness

  
  protected
    def update_filter_value
      if self.entry.is_mainpageable?
        self.is_great       = self.value >= 15
        self.is_good        = self.value >= 5
        self.is_everything  = self.value >= -5
      else
        self.is_great = self.is_good = self.is_everything = false
      end
      
      true
    end
    
    def update_hotness
      require 'bigdecimal'

      score = self.ups - self.downs
      order = Math.log10([score.abs, 1].max)

      if score > 0
        sign = 1
      elsif score < 0
        sign = -1
      else
        sign = 0
      end

      self.hotness = BigDecimal.new((order + (sign * self.entry_id / DAY_LIMIT)).to_s).round(7).to_f
      
      true
    end    
end
