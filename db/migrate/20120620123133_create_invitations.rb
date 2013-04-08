class CreateInvitations < ActiveRecord::Migration
  def self.up
    add_column :users, :invitations_left, :integer, :null => false, :default => 0

    create_table :invitations do |t|
      t.belongs_to :user, :null => false
      t.belongs_to :invitee

      t.string :email

      t.string :code, :limit => 32

      t.timestamps
    end

    add_index :invitations, :user_id
    add_index :invitations, :invitee_id
    add_index :invitations, :code, :unique => true
  end

  def self.down
    remove_column :users, :invitations_left

    drop_table :invitations
  end
end
