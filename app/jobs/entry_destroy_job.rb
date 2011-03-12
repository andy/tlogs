require 'resque/plugins/lock'

class EntryDestroyJob
  @queue = :killers
  
  def self.perform(entry_id)
    entry = Entry.find_by_id(entry_id)
    
    entry.destroy if entry
  end
end