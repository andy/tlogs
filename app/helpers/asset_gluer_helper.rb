module AssetGluerHelper
  def glued_stylesheet_link_tag(group_name, subgroup="default")
    if group = GROUPPED_STYLESHEETS[group_name]
      subgroup_suffix = subgroup == "default" ? "" : ".#{subgroup}"
      cached_file_name = "cache/#{group_name}#{subgroup_suffix}"
      stylesheet_link_tag(group[subgroup], :cache => cached_file_name ) rescue nil
    end
  end
  def glued_javascript_include_tag(group_name)
    if group = GROUPPED_JAVASCRIPTS[group_name]
      cached_file_name = "cache/#{group_name}"
      javascript_include_tag(group, :cache => cached_file_name ) rescue nil
    end
  end
end