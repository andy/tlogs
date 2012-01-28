# encoding: utf-8
module EntryExtensions
  module Navigation
    extend ActiveSupport::Concern
    
    module InstanceMethods
      # Жуткий мезанизм определения на какой странице находится запись
      def page_for(user = nil, zero_if_last = true, options = {})
        is_daylog = options.delete(:is_daylog) || false
        if self.new_record?
          zero_if_last ? 0 : (self.author.entries_count_for(user) / 15.0).ceil
        else
          conditions = "id >= #{self.id}"
          conditions += " AND user_id = #{self.user_id}"
          conditions += if self.is_anonymous?
              " AND type = 'AnonymousEntry'"
            elsif self.is_private?
              " AND is_private = 1 AND type != 'AnonymousEntry'"
            else
              " AND is_private = 0"
            end
          # conditions += " AND is_private = 0" unless (user && user.id == self.user_id)
          entry_offset = Entry.count(:conditions => conditions)
          total_pages = (self.author.entries_count_for(user) / 15.0).ceil
          entry_page = ((entry_offset / Entry::PAGE_SIZE.to_f).floor + 1)
          (zero_if_last && entry_page == total_pages) ? 0 : entry_page
        end
      end
    
      def next(options = {})
        include_private = options.fetch(:include_private, false)
        @next ||= Entry.find_by_sql("SELECT id, created_at, user_id, comments_count, updated_at, is_voteable, is_private, is_mainpageable, comments_enabled FROM entries WHERE id > #{self.id} AND user_id = #{self.user_id}#{' AND is_private = 0 ' unless include_private} LIMIT 1").first rescue nil
      end

      def prev(options = {})
        include_private = options.fetch(:include_private, false)
        @prev ||= Entry.find_by_sql("SELECT id, created_at, user_id, comments_count, updated_at, is_voteable, is_private, is_mainpageable, comments_enabled FROM entries WHERE id < #{self.id} AND user_id = #{self.user_id}#{' AND is_private = 0 ' unless include_private} ORDER BY id DESC LIMIT 1").first rescue nil
      end

      def next_id
        @next_id ||= Entry.find_by_sql("SELECT id FROM entries WHERE id > #{self.id} AND user_id = #{self.user_id} AND is_private = 0 LIMIT 1").first[:id] rescue false
      end
  
      def prev_id
        @prev_id ||= Entry.find_by_sql("SELECT id FROM entries WHERE id < #{self.id} AND user_id = #{self.user_id} AND is_private = 0 ORDER BY id DESC LIMIT 1").first[:id] rescue false
      end
    end
  end
end