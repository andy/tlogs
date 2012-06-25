# == Schema Information
# Schema version: 20110816190509
#
# Table name: comments
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null, indexed
#  comment      :text
#  user_id      :integer(4)      not null, indexed
#  is_disabled  :boolean(1)      default(FALSE), not null
#  created_at   :datetime        not null, indexed
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
  
  has_many :reports


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
    # because disable! did this already
    unless comment.is_disabled?
      comment.decrement_comment_views! unless comment.is_disabled? 

      comment.entry.update_attribute(:updated_at, Time.now)
    end
    
    comment.entry.try_watchers_update # XXX: what's the purpose of this?
  end
  
  after_create do |comment|
    comment.entry.update_attribute(:updated_at, Time.now)    
  end


  ## class methods
  ## public methods
  
  # обновляет счетчик просмотренных комментариев, но только для тех, кто еще не видел комментарий, который был восстановлен
  # (специально для функции restore!)
  def increment_comment_views!
    self.connection.update("UPDATE comment_views SET last_comment_viewed = last_comment_viewed + 1 WHERE entry_id = #{self.entry.id} AND last_comment_viewed <= #{self.entry.comments_count}") if self.entry.comments_count > 0
  end
  
  # обновляем счетчик просмотренных комментариев, но только для тех, кто уже видел комментарий который сейчас был удален
  # (для использования при удалении комменатрия и в функции disable!)
  def decrement_comment_views!
    self.connection.update("UPDATE comment_views SET last_comment_viewed = last_comment_viewed - 1 WHERE entry_id = #{self.entry.id} AND last_comment_viewed > #{self.entry.comments_count - 1}") if self.entry.comments_count > 0
  end

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
  
  # returns true if we might suggest blacklisting comment author by *user* when comment is removed
  # basically, if author is another person and is not in friends with current user then blacklisting might
  # be an option
  def can_be_blacklisted_by?(user)
    user && user.id != self.user.id # && !user.all_friend_ids.include?(self.user.id)
  end
  
  # wether this comment can be reported by user
  def can_be_reported_by?(reporter)
    reporter && reporter.id != self.user_id
  end

  def was_reported_by?(reporter)
    Report.exists? :reporter_id => reporter.id, :content_id => self.id, :content_type => self.class.name
  end
    
  def report!(reporter)
    Report.create :reporter => reporter, :content => self, :content_owner => self.user
  end
  
  def disable!
    return false if self.is_disabled?

    self.update_attribute(:is_disabled, true)
    
    # clean up view for other people
    self.decrement_comment_views!

    # emulate counter cache
    Entry.decrement_counter(:comments_count, self.entry.id)
    
    # this will invalidate all caches for the page with the comments
    self.entry.update_attribute(:updated_at, Time.now)
  end
  
  # comment can only be restored if removed by entry owner
  def can_be_restored_by?(user)
    user && self.entry.user_id == user.id
  end
  
  # opposite of disable!
  def restore!
    return false unless self.is_disabled?
    
    self.update_attribute(:is_disabled, false)
    
    # make this not appear as a new comment
    self.increment_comment_views!
    
    Entry.increment_counter(:comments_count, self.entry.id)
    
    self.entry.update_attribute(:updated_at, Time.now)
  end
  
  # deliver comment 
  def deliver!(current_service, reply_to)
    return false if self.is_disabled?

    users = []

    if !reply_to.blank?
      comment_ids = reply_to.split(',').map(&:to_i)
      # выбирает все комментарии для этой записи и достает оттуда уникальных пользователей
      user_ids  = Comment.find_all_by_id(comment_ids, :conditions => "entry_id = #{entry.id}").map(&:user_id).reject { |id| id <= 0 }.uniq
      users     = User.find(user_ids).reject { |u| !u.email_comments? } if user_ids.any?
    end

    # отправляем комментарий владельцу записи
    if entry.author.is_emailable? && entry.author.email_comments? && entry.author.id != self.user_id
      Emailer.deliver_comment(current_service, entry.author, self)
    end
    
    # отправляем комменатрий каждому пользователю
    users.each do |u|
      Emailer.deliver_comment_reply(current_service, u, self) if u.is_emailable? && u.email_comments? && u.id != entry.author.id
    end
    
    # отправляем сообщение всем тем, кто наблюдает за этой записью, и кому мы еще ничего не отправляли
    (self.entry.subscribers - users).each do |u|
      Emailer.deliver_comment_to_subscriber(current_service, u, self) if u.is_emailable? && u.email_comments? && u.id != self.user_id
    end
    
    # update watchers
    self.entry.try_watchers_update
    
    true
  end

  # do the same delivery, but asynchronously
  def async_deliver!(current_service, reply_to)
    Resque.enqueue(CommentDeliverJob, self.id, current_service.domain, reply_to)
  end


  ## private methods
end
