class AddIsDisabledAndIndexesToConversations < ActiveRecord::Migration
  def self.up
    add_column :conversations, :is_disabled, :boolean, :null => false, :default => false

    add_index :conversations, :is_disabled
    add_index :conversations, :last_message_at
    add_index :conversations, :is_viewed
    add_index :conversations, :is_replied
  end

  def self.down
    remove_column :conversations, :is_disabled

    remove_index :conversations, :is_disabled
    remove_index :conversations, :last_message_at
    remove_index :conversations, :is_viewed
    remove_index :conversations, :is_replied
  end
end
