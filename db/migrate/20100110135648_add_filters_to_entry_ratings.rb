class AddFiltersToEntryRatings < ActiveRecord::Migration
  def self.up
    add_column :entry_ratings, :is_great, :boolean, :default => false, :null => false
    add_column :entry_ratings, :is_good, :boolean, :default => false, :null => false
    add_column :entry_ratings, :is_everything, :boolean, :default => false, :null => false

    add_index :entry_ratings, :entry_type

    add_index :entry_ratings, :is_great
    add_index :entry_ratings, :is_good
    add_index :entry_ratings, :is_everything

    add_index :entry_ratings, [:is_great, :entry_type]
    add_index :entry_ratings, [:is_good, :entry_type]
    add_index :entry_ratings, [:is_everything, :entry_type]

    EntryRating.reset_column_information

    EntryRating.update_all 'is_great = 1', 'value >= 5'
    EntryRating.update_all 'is_good = 1', 'value >= 2'
    EntryRating.update_all 'is_everything = 1', 'value >= -5'
  end

  def self.down
    remove_column :entry_ratings, :is_great
    remove_column :entry_ratings, :is_good
    remove_column :entry_ratings, :is_everything
  end
end
