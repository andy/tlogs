class Entry
  
  def vote(user, rating)
    return unless user.can_vote?(self)
    
    # находим существующую запись
    EntryRating.transaction do
      entry_rating = EntryRating.find_by_entry_id(self.id) or return
    
      # голос пользователя: нам его нужно либо создать, либо использвовать уже имющийся
      user_vote = EntryVote.find_or_initialize_by_entry_id_and_user_id(self.id, user.id)
      # новая запись или пользователь поменял свое мнение?
      if user_vote.new_record? || (rating * user.vote_power) != user_vote.value
        # вычитаем старое значение если пользователь поменял свое мнение
        entry_rating.value -= user_vote.value unless user_vote.new_record? 
        user_vote.value = rating * user.vote_power
        entry_rating.value += user_vote.value

        # сохраняем новое в базу
        user_vote.save && entry_rating.save
      end
    end
  end
  
  def voted?(user)
    EntryVote.find_by_entry_id_and_user_id(self.id, user.id).value rescue 0
  end
  
  # в чем глубокий смысл этого кода?
  def make_voteable(enable=true)
    entry_rating = EntryRating.find_or_initialize_by_entry_id(self.id)
    if enable
      # создаем, при этом восстанавливаем рейтинг у записи - оставляем тот который был
      entry_rating.attributes = { :entry_id => self.id, :entry_type => self.attributes['type'], :value => self.votes.sum(:value) || 0, :user_id => self.user_id } if entry_rating.new_record?
      self.rating = entry_rating
    else
      self.rating = nil
    end
  end
  
end