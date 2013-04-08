class AddDisabledAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :disabled_at, :datetime, :null => true

    User.disabled.paginated_each { |user| user.update_attribute(:disabled_at, user.entries_updated_at) }
  end

  def self.down
    remove_column :users, :disabled_at
  end
end
