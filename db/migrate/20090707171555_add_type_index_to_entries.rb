class AddTypeIndexToEntries < ActiveRecord::Migration
  def self.up
    add_index :entries, :type
  end

  def self.down
    add_index :entries, :type
  end
end
