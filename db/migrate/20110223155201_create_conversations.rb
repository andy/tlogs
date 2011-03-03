class CreateConversations < ActiveRecord::Migration
  def self.up
    create_table :conversations do |t|
      t.integer       :user_id, :null => false
      t.integer       :recipient_id, :null => false

      t.integer       :messages_count, :null => false, :default => 0

      t.boolean       :send_notifications, :null => false, :default => true
      t.boolean       :is_replied, :null => false, :default => false
      t.boolean       :is_viewed, :null => false, :default => false

      t.integer       :last_message_id
      t.integer       :last_message_user_id
      t.timestamp     :last_message_at
      
      t.timestamps
    end
    
    add_index :conversations, [:user_id, :recipient_id], :uniq => true
    add_index :conversations, [:user_id, :last_message_at]
    
    # counter cache for users
    add_column :users, :conversations_count, :integer, :null => false, :default => 0
    remove_column :users, :messages_count
    
    # change messages
    add_column :messages, :conversation_id, :integer, :null => false
    add_column :messages, :recipient_id, :integer, :null => false    

    remove_column :messages, :is_private
    remove_column :messages, :is_disabled
    remove_column :messages, :body_html
    
    # get ready
    User.reset_column_information
    Message.reset_column_information
    
    # migrate messages
    # я, юзер 1, оставил сообщение на странице у юзера 2
    #  - должно появиться два conversations:
    #    - один записанный на юзера 1
    #    - второй записанный на юзера 2
    #       
    
    # 1/ swap this recipient stuff with sender stuff
    say_with_time "Switching recipient and sender fields ..." do
      Message.update_all "recipient_id = user_id"
      Message.update_all "user_id = sender_id"
      remove_column :messages, :sender_id
      Message.reset_column_information
    end

    # 2/ bind all messages to conversations
    last_message_id = Message.last.id
    say "Total messages: #{Message.count}"
    say "Last message: #{last_message_id}"
    
    say_with_time "Migrating messages ..." do
      migrated_count = 0

      Message.paginated_each(:conditions => "messages.id <= #{last_message_id}") do |message|
        # ignore messages that have invalid users (odd)
        next if message.user.nil?

        message.clone.begin_conversation!
        
        migrated_count += 1
      end
      
      migrated_count
    end

    # 3/ remove all messages
    say_with_time "Removing all old messages ..." do
      Message.delete_all ['id <= ?', last_message_id]
    end
    
    # 4/ mark all conversations as viewed
    say_with_time "Marking all conversations as viewed ..." do
      Conversation.update_all 'is_viewed = 1'
    end
  end

  def self.down
    drop_table :conversations
    
    remove_column :users, :conversations_count
    add_column :users, :messages_count, :integer, :null => false, :default => 0

    # restore messages table from dump
  end
end
