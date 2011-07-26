class AddLargeUserpicColumnToTlogDesignSettings < ActiveRecord::Migration
  def self.up
    add_column :tlog_design_settings, :large_userpic, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :tlog_design_settings, :large_userpic
  end
end
