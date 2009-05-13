module CommentsHelper
  def link_to_comment_author(comment, highlight = false)
    html_options = {}
    html_options[:class] = 'highlight' if highlight
    link_to_tlog(comment.user, {}, html_options )
  end
end