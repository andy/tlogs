# encoding: utf-8
module EntryExtensions
  module Tags
    extend ActiveSupport::Concern
    
    included do
      acts_as_taggable
    end

    module ClassMethods
      #
      # Code below goes from markaboo
      #   код для вычисления тегов для текущей записи и для тегов вообще
      #
      DEFAULT_CATEGORY_OPTIONS = {:include_private => false, :max_rows => 10}.freeze
      DEFAULT_FIND_OPTIONS = {:owner => nil, :include_private => false}.freeze
      DEFAULT_PAGE_OPTIONS = {:page => 1, :total => 0, :limit => Entry::PAGE_SIZE}.freeze

      # Used to find a page of bookmarks in a given category/categories either for everyone
      # or a specific user
      def paginate_by_category(categories, page_options, find_options={})
        find_options = DEFAULT_FIND_OPTIONS.merge(find_options)
        page_options = DEFAULT_PAGE_OPTIONS.merge(page_options)
        offset = (page_options[:page] - 1) * page_options[:limit]
    
        conditions = "tags.name IN (#{categories.map(&:sql_quote)})" 
        conditions += " AND entries.user_id = #{find_options[:owner].id}" if find_options[:owner]
        conditions += ' AND entries.is_mainpageable = 1' if find_options[:is_mainpageable]
        conditions += ' AND entries.is_private = 0' unless find_options[:include_private] 
    

        sql = <<-GO
          SELECT entries.id 
          FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id INNER JOIN entries ON entries.id = taggings.taggable_id  
          WHERE #{conditions} 
          ORDER BY entries.id DESC LIMIT #{offset}, #{page_options[:limit]}
        GO
    
        entry_ids = Tag.find_by_sql(sql)
        entry_ids = entry_ids.collect!(&:id)
    
        records = find(entry_ids, :order => 'entries.id DESC', :include => [:author])
        class << records; self end.send(:define_method, :total) {page_options[:total].to_i}    
        class << records; self end.send(:define_method, :limit) {page_options[:limit].to_i}
        class << records; self end.send(:define_method, :offset) {offset}
        records.extend Paginator
        records
      end
  
      # Returns the N most frequent categories (N defaults to 10)
      def top_categories(options={})
        options = DEFAULT_CATEGORY_OPTIONS.merge(options)
    
        conditions = []
        conditions << "entries.user_id = #{options[:owner].id}" if options[:owner]
        conditions << 'entries.is_private = 0' unless options[:include_private]
    
        sql = <<-GO
        SELECT name, COUNT(*) number
        FROM tags 
        INNER JOIN taggings 
        ON tags.id = taggings.tag_id 
        INNER JOIN entries 
        ON taggings.taggable_id = entries.id 
        INNER JOIN users
        ON entries.user_id = users.id
        #{" WHERE %s " % conditions.join(' AND ') unless conditions.blank?}  
        GROUP BY name 
        ORDER BY number DESC, name ASC 
        #{"limit %d " % options[:max_rows] unless options[:max_rows] == -1}
        GO
        result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
        tags = []
        result.each {|row| tags << [row[0], row[1].to_i]} 
        tags
      end
  
      # Use a better-performing query to count the resources associated with a particular tag
      def count_tagged_with(tags, options={})
        options = DEFAULT_FIND_OPTIONS.merge(options)

        conditions = []
        conditions << "tags.name IN (#{tags.map(&:sql_quote)})"
        conditions << 'entries.is_private = 0' unless options[:include_private]
        conditions << 'entries.is_mainpageable = 1' if options[:is_mainpageable]
        conditions << "entries.user_id = #{options[:owner].id}" if options[:owner]

        sql = <<-GO
          SELECT count(distinct entries.id) count_all
          FROM entries 
          INNER JOIN taggings 
          ON entries.id = taggings.taggable_id AND 'Entry' = taggings.taggable_type 
          INNER JOIN tags 
          ON taggings.tag_id = tags.id
          WHERE #{conditions.join(' AND ')}
        GO

        result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
        result.fetch_row[0].to_i
      end
    end
  end
end