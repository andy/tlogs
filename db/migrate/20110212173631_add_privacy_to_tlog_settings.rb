class AddPrivacyToTlogSettings < ActiveRecord::Migration
  def self.up
    add_column :tlog_settings, :privacy, :string, :default => 'open', :null => false, :limit => 16
  end

  def self.down
    remove_column :tlog_settings, :privacy
  end
end
