class AddDeltaToEntries < ActiveRecord::Migration
  def self.up
    add_column :entries, :delta, :boolean, :default => true, :null => false
    add_index :entries, :delta
  end

  def self.down
    remove_column :entries, :delta
  end
end
