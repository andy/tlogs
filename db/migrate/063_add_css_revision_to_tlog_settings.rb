class AddCssRevisionToTlogSettings < ActiveRecord::Migration
  def self.up
    add_column :tlog_settings, :css_revision, :integer, :null => false, :default => 1
  end

  def self.down
    remove_column :tlog_settings, :css_revision
  end
end
