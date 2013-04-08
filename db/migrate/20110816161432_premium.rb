class Premium < ActiveRecord::Migration
  def self.up
    remove_column :users, :is_premium
    add_column    :users, :premium_till,  :datetime,  :default => nil

    drop_table :transactions
    
    create_table :invoices do |t|
      t.belongs_to  :user,        :null => false
      
      t.string      :state,       :null => false

      t.string      :type,        :null => false
      t.string      :metadata,    :null => false
      
      t.float       :amount,      :null => false, :default => 0.0
      t.float       :revenue,     :null => false, :default => 0.0
      t.integer     :days,        :null => false, :default => 0

      t.string      :remote_ip
      
      t.timestamps
    end
    add_index :invoices, :user_id
  end

  def self.down
    add_column :users, :is_premium, :boolean, :null => false, :default => false
    remove_column :users, :premium_till
  end
end