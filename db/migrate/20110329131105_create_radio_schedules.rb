class CreateRadioSchedules < ActiveRecord::Migration
  def self.up
    create_table :radio_schedules do |t|
      t.belongs_to  :user,            :null => false
      t.string      :body,            :null => false
      t.timestamp   :air_at,          :null => false
      t.timestamp   :end_at,          :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :radio_schedules
  end
end
