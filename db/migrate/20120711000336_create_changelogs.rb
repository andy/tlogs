class CreateChangelogs < ActiveRecord::Migration
  def self.up
    create_table :changelogs do |t|
      t.references :owner,  :null => false
      t.references :actor

      t.references :object, :polymorphic => true

      t.string  :action,  :null => false
      t.text    :comment

      t.timestamps
    end

    add_index :changelogs, [:object_id, :object_type]
    add_index :changelogs, :owner_id
    add_index :changelogs, [:owner_id, :action]
    add_index :changelogs, :actor_id
    add_index :changelogs, [:actor_id, :action]
  end

  def self.down
    drop_table :changelogs
  end
end
