# == Schema Information
# Schema version: 20120711194752
#
# Table name: faves
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)      not null, indexed => [entry_id], indexed => [entry_user_id], indexed => [entry_type]
#  entry_id      :integer(4)      not null, indexed => [user_id], indexed
#  entry_type    :string(0)       default("TextEntry"), not null, indexed => [user_id]
#  entry_user_id :integer(4)      not null, indexed => [user_id], indexed => [created_at]
#  created_at    :datetime        indexed => [entry_user_id]
#
# Indexes
#
#  index_faves_on_user_id_and_entry_id          (user_id,entry_id) UNIQUE
#  index_faves_on_user_id_and_entry_user_id     (user_id,entry_user_id)
#  index_faves_on_user_id_and_entry_type        (user_id,entry_type)
#  index_faves_on_entry_id                      (entry_id)
#  index_faves_on_entry_user_id_and_created_at  (entry_user_id,created_at)
#

class Fave < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :entry

  # watchers
  # after_create :update_watchers
  #
  # after_destroy :destroy_watchers

  def is_owner?(user)
    user.id == self.user_id
  end

  # def watcher_ids
  #   self.user.subscriber_ids
  # end
  #
  # # update watchers in a way that does not affect ordering,
  # #  and see if entry is ALREADY present in the watchers queue and if so - skip this
  # def update_watchers
  #   e = self.entry
  #
  #   $redis.multi do
  #     self.watcher_ids.each do |user_id|
  #       eqk = User::entries_queue_key(user_id)
  #
  #       # update timing only if entry's not present yet in queue
  #       $redis.zadd(eqk, e.updated_at.to_i, e.id) unless $redis.zscore(eqk, e.id)
  #     end
  #   end
  # end
end
