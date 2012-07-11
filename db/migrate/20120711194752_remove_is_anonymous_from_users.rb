class RemoveIsAnonymousFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :is_anonymous
  end

  def self.down
  end
end
