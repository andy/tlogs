class CreateBulkTransactions < ActiveRecord::Migration
  def self.up
    create_table :bulk_transactions do |t|
      t.belongs_to :transactions
      
      t.string :service,    :null => false
      t.string :metadata,   :null => false
      t.string :remote_ip,  :null => false
      
      t.timestamps
    end
    
    add_index :bulk_transactions, :transactions_id
  end

  def self.down
    drop_table :bulk_transactions
  end
end
