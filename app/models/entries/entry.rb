# = Schema Information
#
# Table name: *entries*
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      default(0), not null
#  data_part_1      :text
#  data_part_2      :text
#  data_part_3      :text
#  type             :string(255)     default(""), not null
#  is_disabled      :boolean(1)      not null
#  created_at       :datetime        not null
#  metadata         :text
#  comments_count   :integer(4)      default(0), not null
#  updated_at       :datetime
#  is_voteable      :boolean(1)
#  is_private       :boolean(1)      not null
#  cached_tag_list  :text
#  is_mainpageable  :boolean(1)      default(TRUE), not null
#  comments_enabled :boolean(1)      not null
########
class Entry < ActiveRecord::Base
	ENTRY_MAX_LENGTH = 10.kilobytes
	ENTRY_MAX_LINK_LENGTH = 2.kilobytes
	PAGE_SIZE = 15

  ## included modules & attr_*
	attr_accessible :data_part_1
	attr_accessible :data_part_2
	attr_accessible :data_part_3
	cattr_accessor :has_attachment
	serialize :metadata

	concerned_with              :tags,          # теги
	                            :vote,          # методы для голосования
	                            :navigation,    # next / prev, методы для навигации
	                            :kinds,         # типы записей
	                            :visibility     # видимость записей, .visibility


  ## associations
	belongs_to                  :author,
	                            :class_name => 'User',
	                            :foreign_key => 'user_id',
	                            :counter_cache => true
                          
	has_many                    :comments,
	                            :dependent => :destroy,
	                            :order => 'comments.id'
                          
	has_many                    :comment_views,
	                            :class_name => 'CommentViews',
	                            :dependent => :destroy
                          
	has_many                    :attachments,
	                            :dependent => :destroy
                          
	has_one                     :rating,
	                            :class_name => 'EntryRating',
	                            :dependent => :destroy
                          
	has_many                    :votes,
	                            :class_name => 'EntryVote',
	                            :dependent => :destroy
                          
	has_many                    :faves,
	                            :dependent => :destroy
                          
  has_and_belongs_to_many     :subscribers,
                              :class_name => 'User',
                              :join_table => 'entry_subscribers'


  ## plugins
	define_index do
	  indexes :data_part_1
	  indexes :data_part_2
    indexes tags.name, :as => :tag

	  has :type
	  has :user_id
	  has :is_private
	  has :created_at
	  has :updated_at
	  has tags(:id), :as => :tag_ids
	  
	  group_by "user_id"
	  group_by "is_private"
	  
    # where 'entries.is_disabled = 0 AND entries.id < 1000'

	  set_property :delta => :datetime, :threshold => 10.minutes
  end


  ## named_scopes
  named_scope :anonymous, :conditions => { :type => 'AnonymousEntry' }
  named_scope :for_view, :include => [:author, :attachments, :rating], :order => 'entries.id DESC'
  named_scope :private, :conditions => 'entries.is_private = 1 AND entries.type != "AnonymousEntry"'
  named_scope :for_user, lambda { |user| { :conditions => "user_id = #{user.id}" } }

  ## validations
	validates_presence_of :author


  ## callbacks
  before_validation :reset_data_parts_if_blank
  before_create :set_default_metadata

  after_destroy do |entry|
    # удаляем всех подписчиков этой записи
    entry.subscribers.clear
    # уменьшаем счетчик скрытых записей, если эта запись - скрытая
    User.decrement_counter(:private_entries_count, entry.user_id) if entry.is_private?
    # уменьшаем количество просмотренных записей для всех пользователей которые подписаны на ленту, но только если это 
    #  была видимая запись И если она не входила в число _новых_ записей для пользователя который просматривает. Поэтому, как 
    #  критерий мы испльзуем поле last_viewed_at для того чтобы определить входила ли запись в число новых 
    Relationship.update_all "last_viewed_entries_count = last_viewed_entries_count - 1", "user_id = #{entry.user_id} AND last_viewed_entries_count > 0 AND last_viewed_at > '#{entry.created_at.to_s(:db)}'" unless entry.is_private?

    entry.author.update_attributes(:entries_updated_at => Time.now)
  end

  after_create do |entry|
    # счетчик скрытых записей. нам так удобнее делать постраничную навигацию
    User.increment_counter(:private_entries_count, entry.user_id) if entry.is_private?
  end
  
  after_save do |entry|
    # обновляем таймстамп который используется для инвалидации кеша тлоговых страниц, но только в том случае
    #  если меняются штуки отличные от комментариев
    entry.author.update_attributes(:entries_updated_at => Time.now) unless (entry.changes.keys - ['comments_count', 'updated_at']).blank?
  end


  ## class methods
  def self.new_from_bm(params)
    self.new :data_part_2 => params[:url], :data_part_1 => params[:c], :data_part_3 => params[:title]
  end
  

  ## public methods
    
  # Могут ли у этой записи быть аттачи? По умолчанию аттачменты отключены
  def can_have_attachments?
    false
  end
  
  def attachment_class; Attachment; end
  
  # Анонимная запись или нет?
  def is_anonymous?
    self[:type] == 'AnonymousEntry'
  end

  # может ли пользователь удалять запись?
  def can_delete?(user)
    user && user.id == self.user_id
  end  
  
  # русское написание
  def to_russian(key=:who)
    entry_russian_dict[key]
  end
    
  ## private methods
  protected
    # выставляем значение в NULL чтобы не было пустышек в базе
    def reset_data_parts_if_blank
      self.data_part_1 = nil if self.data_part_1.blank?
      self.data_part_2 = nil if self.data_part_2.blank?
      self.data_part_3 = nil if self.data_part_3.blank?
      true
    end    
    
    # добавляет префикс http:// к ссылке если она вообще похожа на ссылку
    def make_a_link_from_data_part_1_if_present
      self.data_part_1 = make_a_link_from_data(self.data_part_1)
      true  
    end

    # добавляет префикс http:// к ссылке если она вообще похожа на ссылку
    def make_a_link_from_data_part_3_if_present
      self.data_part_3 = make_a_link_from_data(self.data_part_3)
      true  
    end
    
    def no_attachment
      !self.has_attachment
    end
  
  private
    # делает ссылку из строки. это нужно в нескольких моделях сразу, где пользователь может ввести ссылку на
    # какой-нибудь адрес при этом не указав http:// в начале. Чтобы потом не возиться - возимся сразу
    def make_a_link_from_data(data)
      return data if data.blank?
      return data if data.strip =~ Format::LINK
      data = 'http://' + data.strip if data.strip.split(/(:|\/)/)[0] =~ Format::DOMAIN
      data
    end

    def set_default_metadata
      begin
  	    self.metadata ||= {}
  	  rescue ActiveRecord::SerializationTypeMismatch
  	    self.metadata = {}
      end
  	  true
    end    
end
