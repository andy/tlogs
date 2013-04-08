class MessageDeliverJob
  @queue = :high

  def self.perform(message_id, service_domain)
    message = Message.find_by_id(message_id)

    if message
      current_service = Tlogs::Domains::CONFIGURATION.options_for(service_domain, nil)
      message.deliver!(current_service)
    end
  end
end
