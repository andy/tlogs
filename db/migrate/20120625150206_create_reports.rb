class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.references :reporter, :null => false      
    
      t.references :content,        :polymorphic => true, :null => false
      t.references :content_owner,  :null => false
    
      t.timestamps
    end

    # this is how we look who reported or who is being reported more often
    add_index :reports, [:reporter_id]
    add_index :reports, [:content_owner_id]

    # this is how we search for specific content
    add_index :reports, [:content_id, :content_type]
    
    # to make sure you can report only once
    add_index :reports, [:reporter_id, :content_id, :content_type], :unique => true
  end

  def self.down
    drop_table :reports
  end
end
