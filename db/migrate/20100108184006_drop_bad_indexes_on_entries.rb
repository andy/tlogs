class DropBadIndexesOnEntries < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE entries DROP INDEX index_entries_on_user_id_and_created_at_and_type"
    execute "ALTER TABLE entries DROP INDEX index_entries_on_is_mainpageable_and_created_at_and_type"
    execute "ALTER TABLE entries DROP INDEX index_entries_on_user_id_and_is_private_and_created_at"
    execute "ALTER TABLE entries DROP INDEX tmpindex"
    execute "ALTER TABLE entries DROP INDEX tmpindex2"
    execute "ALTER TABLE entries DROP INDEX index_entries_on_is_mainpageable_and_is_private_and_id"
    execute "ALTER TABLE entries DROP INDEX index_entries_on_is_mainpageable_and_id"

    add_index :entries, :user_id
    add_index :entries, :is_private
    add_index :entries, :is_voteable
    add_index :entries, :created_at
  end

  def self.down
  end
end
