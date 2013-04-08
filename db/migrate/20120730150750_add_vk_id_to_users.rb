class AddVkIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :vk_id, :integer
    
    add_index :users, :vk_id
  end

  def self.down
    remove_column :users, :vk_id
  end
end
