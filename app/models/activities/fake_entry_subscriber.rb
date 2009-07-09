class FakeEntrySubscriber < ActiveRecord::Base
  set_table_name 'entry_subscribers'
  set_primary_key 'entry_id'
end