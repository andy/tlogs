module PublishHelper
  def empty_bookmarklet_url_options(options={})
    options = %w(url title c tags vis autosave).inject(options) { |opts, k| opts.update("bm[#{k}]" => nil) } if in_bookmarklet?
    options
  end

  def bookmarklet_url_options(options={})
    options = %w(url title c tags vis autosave).inject(options) { |opts, k| opts.update("bm[#{k}]" => params[:bm][k]) } if in_bookmarklet?
    options
  end
  
  def entry_visibility_new(user)
    Entry::VISIBILITY_FOR_SELECT_NEW.select { |v| user.is_allowed_visibility?(v[1]) }
  end
  
  def entry_visibility_edit(user, entry)
    Entry::VISIBILITY_FOR_SELECT_EDIT.select { |v| entry.visibility == v[1] || user.is_allowed_visibility?(v[1]) }
  end
end
