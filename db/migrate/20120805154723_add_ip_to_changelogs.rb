class AddIpToChangelogs < ActiveRecord::Migration
  def self.up
    add_column :changelogs, :ip, :string, :limit => 16

    add_index :changelogs, :ip
    add_index :changelogs, [:owner_id, :ip]
    add_index :changelogs, :action
  end

  def self.down
    remove_column :changelogs, :ip
  end
end
