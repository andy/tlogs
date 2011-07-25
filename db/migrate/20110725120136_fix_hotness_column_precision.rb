class FixHotnessColumnPrecision < ActiveRecord::Migration
  def self.up
    change_column :entry_ratings, :hotness, :decimal, :precision => 32, :scale => 12, :default => 0
  end

  def self.down
    raise IrreversibleMigration
  end
end
