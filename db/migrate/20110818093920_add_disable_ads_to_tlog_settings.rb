class AddDisableAdsToTlogSettings < ActiveRecord::Migration
  def self.up
    add_column :tlog_settings, :disable_ads, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :tlog_settings, :disable_ads
  end
end
