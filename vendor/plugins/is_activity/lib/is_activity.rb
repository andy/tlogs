module IsActivity
  
  DEFAULT_CONFIGURATION = {
    :belongs_to            => :resource,
    :polymorphic           => true
  }.freeze
  
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def group_activities(all_activities)
      # на время скроем дружскую активность
      filtered_activities = all_activities.select{ |activity| activity.class.name != "FriendshipActivity" }

      activities_in_groups = filtered_activities.group_by{|activity| activity.gluing_params}

      activities = activities_in_groups.map do |group|
        klass = group.first[0]
        activities = group.last.sort{|a, b| b.created_at <=> a.created_at}

        if klass.constantize.glue?
          # Склеиваемая активность выплывает наверх с учетом так называемых "задержек" (с) Вася.
          # При сортировке учитывается дата не последней активности этой группы, а последняя активности,
          # являющаяся наибольшей степенью двойки, не превосходящей количества активностей в группе.
          # Например, на событие собираются 55 друзей. Склеенная активность сортируется по 32-ой активности,
          # в нее входящей. Когда набирается 64 друга, она начнает сортироваться по 64-ой активности, а значит всплывает
          # в ленте активности.
          # Чем дальше, тем труднее всплыть.
          top = (2 ** (activities.size.to_s(base=2).length - 1)) - 1
          activities[top].glued_field = activities.map(&:glued_field)
          activities[top].favorite = activities.map{|activity| activity.favorite}.include?(true)
          activities[top]
        else
          activities
        end
      end.flatten.sort{|a, b| b.created_at <=> a.created_at}
      activities
    end

    # проставляет атрибут favorite каждой активности из коллекции
    def mark_favorites(user, collection)
      return collection if user.guest? || collection.blank?
      favorite_friend_ids = user.find_favorite_friend_ids
      collection.each {|activity| activity.favorite = favorite_friend_ids.include?(activity.user_id) }
    end

    def is_activity(options={})
      options.reverse_merge!(DEFAULT_CONFIGURATION)
      options.assert_valid_keys(DEFAULT_CONFIGURATION.keys)

      # показатель того, от избранного ли друга эта активность произошла 
      attr_accessor :favorite

      stored_attributes :login, :cached_resource
      
      # создатель активности
      belongs_to :user
      
      belongs_to options[:belongs_to], :polymorphic => options[:polymorphic]
      
      # совместимость на метод resource, если не полиморфическая связь
      belongs_to(:resource, :class_name => options[:belongs_to].to_s.classify, :foreign_key => options[:belongs_to].to_s.foreign_key) unless options[:polymorphic]
      
      # активность пользователя и ресурса (с учетом полиморфа)
      named_scope :by_user_and_resource, lambda {|user, resource| {:conditions => (options[:polymorphic] ? resource.to_poly_params : {options[:belongs_to].to_s.foreign_key.to_sym => resource.id}).merge(:user_id => user.get_id)}}
      
      # активность для пользователя
      named_scope :for_user, lambda {|user| {:conditions => {:user_id => user.activity_user_ids}}}

      # активность пользователя
      named_scope :of_user, lambda {|user| {:conditions => {:user_id => user.id}}}
      
      named_scope :expired, lambda { {:conditions => ["created_at<=?", 3.days.ago] } }
      
      validates_presence_of :user_id
      
      before_create :save_stored_attributes
      
      # для совместимости отвечает также на resource_type и resource_id
      unless options[:polymorphic]
        class_eval <<-EOV
          def resource_type
            "#{options[:belongs_to]}".classify
          end
          
          def resource_id
            #{options[:belongs_to].to_s.foreign_key}
          end
        EOV
      end
      
      # склеивать ли активность разных пользователей?
      def glue?; false; end
      
      include IsActivity::InstanceMethods
    end
  end
  
  module InstanceMethods
    
    def glued_field
      @glued_field || cached_resource
    end
    
    def glued_field=(*opts)
      @glued_field = opts.first
    end
    
    def gluing_params
      [self.class.name, self.resource_type, self.resource_id]
    end

    protected
    
    def save_stored_attributes
      self.login = user.login
    end
    
    def delete_previous
      self.class.by_user_and_resource(user, resource).delete_all
    end
    
  end
  
end
