class AddVoteCountsToEntryRatings < ActiveRecord::Migration
  def self.up
    add_column :entry_ratings, :ups, :integer, :null => false, :default => 0
    add_column :entry_ratings, :downs, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :entry_ratings, :ups
    remove_column :entry_ratings, :downs
  end
end
