class MainBackground < ActiveRecord::Migration
  def self.up
    # paperclip plugin
    add_column :tlog_settings, :main_background_file_name,   :string
    add_column :tlog_settings, :main_background_updated_at,  :datetime

    # paperclip-meta plugin
    add_column :tlog_settings, :main_background_meta,        :text
  end

  def self.down
    remove_column :tlog_settings, :main_background_file_name
    remove_column :tlog_settings, :main_background_updated_at
    remove_column :tlog_settings, :main_background_meta
  end
end
