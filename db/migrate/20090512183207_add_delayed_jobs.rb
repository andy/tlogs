class AddDelayedJobs < ActiveRecord::Migration
  def self.up
    create_table :delayed_jobs, :force => true do |table|
      table.integer  :priority, :default => 0
      table.integer  :attempts, :default => 0
      table.text     :handler
      table.string   :last_error
      table.datetime :run_at
      table.datetime :locked_at
      table.string   :locked_by
      table.timestamps
    end

    add_index :delayed_jobs, :priority
    add_index :delayed_jobs, :attempts
    add_index :delayed_jobs, :run_at
    add_index :delayed_jobs, :locked_at
    add_index :delayed_jobs, :locked_by
  end

  def self.down
    drop_table :delayed_jobs
  end
end
