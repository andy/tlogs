class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.belongs_to    :user,      :null => false
      t.integer       :amount,    :null => false
      
      t.string        :state, :default => 'pending', :null => false

      t.timestamps
    end
    
    add_index :transactions, :user_id
    add_index :transactions, :state
  end

  def self.down
    drop_table :transactions
  end
end
