# == Schema Information
# Schema version: 20110223155201
#
# Table name: comments
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null
#  comment      :text
#  user_id      :integer(4)      not null
#  is_disabled  :boolean(1)      default(FALSE), not null
#  created_at   :datetime        not null
#  updated_at   :datetime
#  comment_html :text
#  remote_ip    :string(17)
#
# Indexes
#
#  index_comments_on_entry_id    (entry_id)
#  index_comments_on_user_id     (user_id)
#  index_comments_on_created_at  (created_at)
#

class Comment < ActiveRecord::Base
  ## included modules & attr_*
  attr_accessible :comment


  ## associations
  belongs_to :entry, :counter_cache => :comments_count
  belongs_to :user


  ## plugins
  ## named_scopes
  named_scope                   :enabled,   :conditions => 'is_disabled = 0'
  named_scope                   :disabled,  :conditions => 'is_disabled = 1'
  
  
  ## validations
  validates_presence_of         :entry_id

  validates_presence_of         :user_id
  
  validates_presence_of         :comment,
                                :on => :create,
                                :message => "куда ж без комментария!"

  validates_length_of           :comment,
                                :within => 1..2000


  ## callbacks
  after_destroy do |comment|
    # обновляем счетчик просмотренных комментариев но только для тех, кто уже видел комментарий который сейчас был удален
    comment.connection.update("UPDATE comment_views SET last_comment_viewed = last_comment_viewed - 1 WHERE entry_id = #{comment.entry.id} AND last_comment_viewed > #{comment.entry.comments.size - 1}")
    comment.entry.update_attribute(:updated_at, Time.now)
    
    comment.entry.try_watchers_update
  end
  
  after_create do |comment|
    comment.entry.update_attribute(:updated_at, Time.now)    
  end


  ## class methods
  ## public methods

  #
  # <%= comment.fetch_cached_or_run_block { |text| white_list_comment text }
  def fetch_cached_or_run_block(&block)
    return self.comment_html unless self.comment_html.blank?
    self.comment_html = block.call self.comment
    self.save unless self.new_record?

    self.comment_html
  end
  
  # сохраняет параметры комментария
  def request=(request)
    self.remote_ip = request.remote_ip
  end
  
  # Может ли пользователь %user удалять этот комментарий?
  #  можно передать entry, которая должна быть той же записью что и self.entry, но при обращении к self.entry
  #  вызывается лишний SQL запрос, и этого можно избежать, передав entry вторым аргументом
  def is_owner?(user, entry=nil)
    entry ||= self.entry
    user && (user.id == self.user_id || user.id == entry.user_id)
  end
  
  # deliver comment 
  def deliver!(current_service, reply_to)
    users = []

    if !reply_to.blank?
      comment_ids = reply_to.split(',').map(&:to_i)
      # выбирает все комментарии для этой записи и достает оттуда уникальных пользователей
      user_ids  = Comment.find(comment_ids, :conditions => "entry_id = #{@entry.id}").map(&:user_id).reject { |id| id <= 0 }.uniq
      users     = User.find(user_ids).reject { |u| !u.email_comments? }
    end

    # отправляем комментарий владельцу записи
    if entry.author.is_emailable? && entry.author.email_comments? && entry.author.id != self.user_id
      Emailer.deliver_comment(current_service, user, self)
    end
    
    # отправляем комменатрий каждому пользователю
    users.each do |user|
      Emailer.deliver_comment_reply(current_service, user, self) if user.is_emailable? && user.email_comments? && user.id != entry.author.id
    end
    
    # отправляем сообщение всем тем, кто наблюдает за этой записью, и кому мы еще ничего не отправляли
    (self.entry.subscribers - users).each do |user|
      Emailer.deliver_comment_to_subscriber(current_service, user, self) if user.is_emailable? && user.email_comments? && user.id != entry.author.id
    end
  end

  # do the same delivery, but asynchronously
  def async_deliver!(current_service, reply_to)
    Resque.enqueue(CommentEmailJob, self.id, current_service.domain, reply_to)
  end
  ## private methods
end
