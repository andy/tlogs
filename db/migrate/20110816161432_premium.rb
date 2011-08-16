class Premium < ActiveRecord::Migration
  def self.up
    remove_column :users, :is_premium
    add_column :users, :premium_till, :datetime, :default => nil
    
    add_column :transactions, :type, :string, :null => false
    add_column :transactions, :service, :string, :null => false
  end

  def self.down
    raise IrreversibleMigration
  end
end
