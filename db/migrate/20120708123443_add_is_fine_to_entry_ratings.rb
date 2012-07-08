class AddIsFineToEntryRatings < ActiveRecord::Migration
  def self.up
    add_column :entry_ratings, :is_fine, :boolean, :null => false, :default => false
    add_index :entry_ratings, :is_fine
  end

  def self.down
    remove_column :entry_ratings, :is_fine
  end
end
