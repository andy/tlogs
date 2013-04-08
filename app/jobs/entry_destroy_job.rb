require 'resque/plugins/lock'

class EntryDestroyJob
  extend Resque::Plugins::Lock

  @queue = :low
  
  def self.perform(entry_id)
    entry = Entry.find_by_id(entry_id)
    
    entry.destroy if entry
  end
end