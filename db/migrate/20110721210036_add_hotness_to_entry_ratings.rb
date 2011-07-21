class AddHotnessToEntryRatings < ActiveRecord::Migration
  def self.up
    add_column :entry_ratings, :hotness, :float, :null => false, :default => 0.0
    
    add_index :entry_ratings, :hotness
  end

  def self.down
    remove_column :entry_ratings, :hotness
  end
end
