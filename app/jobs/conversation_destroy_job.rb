class ConversationDestroyJob
  @queue = :low
  
  def self.perform(convo_id)
    convo = Conversation.find_by_id(convo_id)
    
    convo.destroy if convo
  end
end