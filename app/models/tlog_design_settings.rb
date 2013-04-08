# == Schema Information
# Schema version: 20110816190509
#
# Table name: tlog_design_settings
#
#  id                              :integer(4)      not null, primary key
#  user_id                         :integer(4)      indexed
#  theme                           :string(255)
#  background_url                  :string(255)
#  date_style                      :string(255)
#  user_css                        :text
#  created_at                      :datetime
#  updated_at                      :datetime
#  color_bg                        :string(6)
#  color_tlog_text                 :string(6)
#  color_tlog_bg                   :string(6)
#  color_sidebar_text              :string(6)
#  color_sidebar_bg                :string(6)
#  color_link                      :string(6)
#  color_highlight                 :string(6)
#  color_date                      :string(6)
#  color_voter_bg                  :string(6)
#  color_voter_text                :string(6)
#  background_fixed                :boolean(1)      default(FALSE), not null
#  color_tlog_bg_is_transparent    :boolean(1)      default(FALSE), not null
#  color_sidebar_bg_is_transparent :boolean(1)      default(FALSE), not null
#  color_voter_bg_is_transparent   :boolean(1)      default(FALSE), not null
#  large_userpic                   :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_tlog_design_settings_on_user_id  (user_id) UNIQUE
#

class TlogDesignSettings < ActiveRecord::Base
  belongs_to :user
  has_one :tlog_background, :dependent => :destroy
  
  # validates_format_of :theme, :with => /^[a-z0-9\_-]+$/i, :if => Proc.new { |t| !t.theme.blank? }  
end
