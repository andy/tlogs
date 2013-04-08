class DeleteAnonymousComments < ActiveRecord::Migration
  def self.up
    remove_column :comments, :ext_url
    remove_column :comments, :ext_username

    # удаляем все старые анонимные комментарии
    execute "DELETE FROM comments WHERE user_id IS NULL OR user_id = '0'"

    # добавляем флаг not null к user_id
    execute "ALTER TABLE comments MODIFY user_id INT(11) NOT NULL"

    remove_index :comments, [:entry_id, :user_id]
    # add_index :comments, :entry_id
    add_index :comments, :user_id
    add_index :comments, :created_at
  end

  def self.down
    raise IrreversibleMigration
  end
end
