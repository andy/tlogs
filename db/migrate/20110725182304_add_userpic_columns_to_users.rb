class AddUserpicColumnsToUsers < ActiveRecord::Migration
  def self.up
    # paperclip plugin
    add_column :users, :userpic_file_name,   :string
    add_column :users, :userpic_updated_at,  :datetime

    # paperclip-meta plugin
    add_column :users, :userpic_meta,        :text
  end

  def self.down
    remove_column :users, :userpic_file_name
    remove_column :users, :userpic_updated_at
    remove_column :users, :userpic_meta
  end
end
