class User
  ## included modules & attr_*
  DEFAULT_CATEGORY_OPTIONS = {:include_private => false, :max_rows => 10}.freeze
  DEFAULT_FIND_OPTIONS = {:owner => nil, :include_private => false}.freeze

  ## associations
  ## plugins
  ## named_scopes
  ## validations
  ## callbacks
  ## class methods
  ## public methods

  # Get the tags for a user
  def tags(include_private=false)
    Tag.find_all_by_user(self, include_private)
  end

  def tag_count
    sql = <<-GO
    SELECT DISTINCT tags.id
    FROM users
    INNER JOIN entries
    on users.id = entries.user_id
    INNER JOIN taggings
    ON entries.id = taggings.taggable_id and 'Entry' = taggings.taggable_type
    INNER JOIN tags
    ON taggings.tag_id = tags.id
    WHERE users.id = #{self.id}

    GO
    result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
    result.num_rows
  end

  # Returns the N most frequent categories for this user (N defaults to 10)
  def top_categories(options={})
    options = DEFAULT_CATEGORY_OPTIONS.merge(options)

    sql = <<-GO
    SELECT tags.name, COUNT(*) number
    FROM users
    INNER JOIN entries
    ON users.id = entries.user_id
    INNER JOIN taggings
    ON entries.id = taggings.taggable_id and 'Entry' = taggings.taggable_type
    INNER JOIN tags
    ON taggings.tag_id = tags.id
    WHERE users.id = #{self.id}
    #{' AND entries.is_private = 0 ' unless options[:include_private] == true}
    GROUP BY tags.name
    ORDER BY number DESC, tags.name ASC
    #{"limit %d " % options[:max_rows] unless options[:max_rows] == 0}
    GO

    result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
    tags = []
    result.each {|row| tags << [row[0], row[1].to_i]}
    tags
  end

  def find_tagged_with(tags, options={})
    options = DEFAULT_FIND_OPTIONS.merge(options)
    sql = <<-GO
      SELECT entries.*
      FROM entries
      INNER JOIN taggings
      ON entries.id = taggings.taggable_id and 'Entry' = taggings.taggable_type
      INNER JOIN tags
      ON taggings.tag_id = tags.id
      WHERE  #{'entries.is_private = 0 and' unless options[:include_private]}
      entries.user_id = #{self.id} and tags.name IN (#{tags.to_query})
    GO
    result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
    result.fetch_row[0].to_i
  end

  def count_tagged_with(tags, options={})
    options = DEFAULT_FIND_OPTIONS.merge(options)
    sql = <<-GO
      SELECT count(distinct entries.id) count_all
      FROM entries
      INNER JOIN taggings
      ON entries.id = taggings.taggable_id and 'Entry' = taggings.taggable_type
      INNER JOIN tags
      ON taggings.tag_id = tags.id
      WHERE  #{'entries.is_private = 0 and' unless options[:include_private]}
      entries.user_id = #{self.id} and tags.name IN (#{tags.to_query})
    GO
    result = connection.execute(sql.gsub("\n", ' ').squeeze(' '))
    result.fetch_row[0].to_i
  end

  def tag_cloud(options = {})
    options[:max_rows] = 50 unless options[:max_rows]
    Tag.cloud { self.top_categories(options) }
  end

  ## private methods

end
