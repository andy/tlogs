class MessageEmailJob
  @queue = :mailout
  
  def self.perform(id)
  end
end