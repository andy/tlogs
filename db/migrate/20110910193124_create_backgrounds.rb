class CreateBackgrounds < ActiveRecord::Migration
  def self.up
    create_table :backgrounds do |t|
      t.belongs_to :user, :null => false

      # paperclip plugin
      t.string    :image_file_name, :null => false
      t.datetime  :image_updated_at

      # paperclip-meta plugin
      t.text      :image_meta

      t.boolean   :is_public, :default => false, :null => false

      t.timestamps
    end

    add_column :tlog_settings, :background_id, :integer

    add_index :backgrounds, :user_id
  end

  def self.down
    drop_table :backgrounds

    remove_column :tlog_settings, :background_id
  end
end
