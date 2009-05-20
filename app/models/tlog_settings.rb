# = Schema Information
#
# Table name: *tlog_settings*
#
#  id                     :integer(4)      not null, primary key
#  user_id                :integer(4)      default(0), not null
#  title                  :string(255)
#  about                  :text
#  updated_at             :datetime
#  rss_link               :string(255)
#  tasty_newsletter       :boolean(1)      default(TRUE), not null
#  default_visibility     :string(255)     default("mainpageable"), not null
#  comments_enabled       :boolean(1)
#  css_revision           :integer(4)      default(1), not null
#  sidebar_is_open        :boolean(1)      default(TRUE), not null
#  is_daylog              :boolean(1)      not null
#  sidebar_hide_tags      :boolean(1)      default(TRUE), not null
#  sidebar_hide_calendar  :boolean(1)      not null
#  sidebar_hide_search    :boolean(1)      not null
#  sidebar_hide_messages  :boolean(1)      not null
#  sidebar_messages_title :string(255)
#  email_messages         :boolean(1)      default(TRUE), not null
#  past_disabled          :boolean(1)      not null
########
class TlogSettings < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user_id
  validates_inclusion_of :default_visibility, :in => %(public private mainpageable voteable), :on => :save
  
  def default_visibility
    read_attribute(:default_visibility) || 'mainpageable'
  end
  
  # обновляем счетчик последнего обновления, чтобы сбросить кеш для страниц.
  #  это актуально когда пользователь переключается между режимами "обычный" / "тлогодень"
  #  и когда он включает / выключает опцию "скрыть прошлое"
  after_save do |record|
    record.user.update_attributes(:entries_updated_at => Time.now) unless (record.changes.keys - ['updated_at']).blank?
  end
end