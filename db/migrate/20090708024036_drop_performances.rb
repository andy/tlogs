class DropPerformances < ActiveRecord::Migration
  def self.up
    drop_table :performances
  end

  def self.down
    raise IrreversibleMigration
  end
end
