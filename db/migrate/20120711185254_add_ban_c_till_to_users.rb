class AddBanCTillToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ban_c_till, :datetime
  end

  def self.down
    remove_column :users, :ban_c_till
  end
end
