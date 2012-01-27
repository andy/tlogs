# encoding: utf-8
class User
  ## included modules & attr_*
  ## associations
  ## plugins
  ## scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods

  # User.find(1).calendar.each do |day, entries|
  def calendar(date=nil)
    date ||= Date.today
    time = date.to_time    
    start_at = time.since(1.month).at_end_of_month
    end_at = time.ago(1.month).at_beginning_of_month

    Rails.cache.fetch("calendar_#{self.id}_#{self.entries_count}_#{start_at.to_i}_#{end_at.to_i}", :expires_in => 2.days) do
      calendar = Entry.find_by_sql(['SELECT id, created_at, DATE_FORMAT(created_at, "%d-%m-%y") day, count(*) as count FROM entries WHERE user_id = ? AND is_private = 0 AND created_at < ? AND created_at > ? GROUP BY day ORDER BY created_at ASC', self.id, start_at.to_s(:db), end_at.to_s(:db)])
      calendar.group_by { |entry| entry.created_at.month }.sort_by { |a| a[1].first.created_at.to_i }
    end
  end

  # Abstract calendar
  def self.calendar(date = nil)
    date      ||= Date.today
    time        = date.to_time
    start_at    = time.ago(1.month).at_beginning_of_month
    end_at      = time.since(1.month).at_end_of_month
    end_at      = Date.tomorrow.to_time if end_at > Date.today
    
    result      = {}
    while start_at < end_at do
      result[start_at.month] ||= []
      result[start_at.month] << start_at
      
      start_at += 1.day
    end
    
    result.sort_by { |m, d| ("%04d%02d" % [d.first.year, d.first.month]).to_i }
  end

  ## private methods
end