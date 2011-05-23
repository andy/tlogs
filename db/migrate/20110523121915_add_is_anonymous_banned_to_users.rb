class AddIsAnonymousBannedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ban_ac_till, :datetime
  end

  def self.down
    remove_column :users, :ban_ac_till, :datetime
  end
end
