# == Schema Information
# Schema version: 20120711194752
#
# Table name: entry_ratings
#
#  id            :integer(4)      not null, primary key
#  entry_id      :integer(4)      default(0), not null, indexed
#  entry_type    :string(0)       default("TextEntry"), not null, indexed => [value], indexed, indexed => [is_great], indexed => [is_good], indexed => [is_everything]
#  created_at    :datetime        not null
#  user_id       :integer(4)      default(0), not null
#  value         :integer(4)      default(0), not null, indexed => [entry_type]
#  is_great      :boolean(1)      default(FALSE), not null, indexed, indexed => [entry_type]
#  is_good       :boolean(1)      default(FALSE), not null, indexed, indexed => [entry_type]
#  is_everything :boolean(1)      default(FALSE), not null, indexed, indexed => [entry_type]
#  ups           :integer(4)      default(0), not null
#  downs         :integer(4)      default(0), not null
#  hotness       :decimal(32, 12) default(0.0), not null, indexed
#  is_fine       :boolean(1)      default(FALSE), not null, indexed
#
# Indexes
#
#  index_entry_ratings_on_entry_id                      (entry_id) UNIQUE
#  index_entry_ratings_on_value_and_entry_type          (value,entry_type)
#  index_entry_ratings_on_entry_type                    (entry_type)
#  index_entry_ratings_on_is_great                      (is_great)
#  index_entry_ratings_on_is_good                       (is_good)
#  index_entry_ratings_on_is_everything                 (is_everything)
#  index_entry_ratings_on_is_great_and_entry_type       (is_great,entry_type)
#  index_entry_ratings_on_is_good_and_entry_type        (is_good,entry_type)
#  index_entry_ratings_on_is_everything_and_entry_type  (is_everything,entry_type)
#  index_entry_ratings_on_hotness                       (hotness)
#  index_entry_ratings_on_is_fine                       (is_fine)
#

class EntryRating < ActiveRecord::Base
  belongs_to :entry

  DAY_LIMIT = 2000.0

  RATINGS = {
    :great => { :select => 'Прекрасное (+50 и круче)', :header => 'Прекрасное', :filter => 'entry_ratings.is_great = 1', :order => 1 },
    :good => { :select => 'Интересное (+15 и выше)', :header => 'Интересное', :filter => 'entry_ratings.is_good = 1', :order => 2 },
    :fine => { :select => 'Хорошее (+5 и выше)', :header => 'Хорошее', :filter => 'entry_ratings.is_good = 1', :order => 3 },
    :everything => { :select => 'Всё подряд (-5 и больше)', :header => 'Всё подряд', :filter => 'entry_ratings.is_everything = 1', :order => 4 }
  }
  RATINGS_FOR_SELECT = RATINGS.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:select], k.to_s] }

  validates_presence_of :user_id
  validates_presence_of :entry_id
  validates_presence_of :entry_type

  before_save :update_filter_value

  before_save :update_hotness

  after_create  :enqueue
  after_destroy :dequeue
  after_update  :requeue

  protected
    def rebuild
      # console version
      # r.ups = r.entry.votes.positive.reject { |v| v.user.nil? || v.user.is_disabled? }.length
      # r.downs = r.entry.votes.negative.reject { |v| v.user.nil? || v.user.is_disabled? }.length
      # r.value = r.entry.votes.reject { |v| v.user.nil? || v.user.is_disabled? }.sum(&:value)
      # r.save
      self.ups    = self.entry.votes.positive.reject { |v| v.user.nil? || v.user.is_disabled? }.length
      self.downs  = self.entry.votes.negative.reject { |v| v.user.nil? || v.user.is_disabled? }.length
      self.value  = self.entry.votes.reject { |v| v.user.nil? || v.user.is_disabled? }.sum(&:value)

      self.save
    end

    def update_filter_value
      if self.entry.is_mainpageable?
        self.is_great       = self.value >= 50
        self.is_good        = self.value >= 15
        self.is_fine        = self.value >= 5
        self.is_everything  = self.value >= -5

      else
        self.is_great = self.is_good = self.is_everything = self.is_fine = false
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

    def type_queue(name)
      [name, entry_type.underscore].join(':')
    end

    def enqueue
      EntryQueue.new('everything').push(entry_id)
      EntryQueue.new(type_queue('everything')).push(entry_id)

      true
    end

    def dequeue
      %w(everything fine good great).each do |name|
        EntryQueue.new(name).delete(entry_id)
        EntryQueue.new(type_queue(name)).delete(entry_id)

        EntryQueue.new('worst').delete(entry_id) if name == 'everything'
      end

      true
    end

    def requeue(force = false)
      %w(great good fine everything).each do |name|
        next unless changes.keys.include?("is_#{name}") || force

        should_present = entry.is_mainpageable? && send("is_#{name}?")
        EntryQueue.new(name).toggle(entry_id, should_present)
        EntryQueue.new(type_queue(name)).toggle(entry_id, should_present)

        EntryQueue.new('worst').toggle(entry_id, !should_present) if name == 'everything'
      end

      true
    end
end
