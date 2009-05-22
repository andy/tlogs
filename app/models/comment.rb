# = Schema Information
#
# Table name: *comments*
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null
#  comment      :text
#  user_id      :integer(4)      not null
#  is_disabled  :boolean(1)      not null
#  created_at   :datetime        not null
#  updated_at   :datetime
#  comment_html :text
#  remote_ip    :string(17)
########
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
  end
  
  after_create do |comment|
    comment.entry.update_attribute(:updated_at, Time.now)
  end


  ## class methods
  ## public methods

  #
  # <%= comment.store_preprocessed_comment { |text| white_list_anonymous_comment text }
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


  ## private methods  


end
