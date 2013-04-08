class CommentEraseJob
  @queue = :high

  def self.perform(entry_id, user_id)
    Entry.find(entry_id).erase_comments_by User.find(user_id)
  end
end
