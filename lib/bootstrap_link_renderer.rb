class BootstrapLinkRenderer < WillPaginate::LinkRenderer
  protected

  def page_link(page, text, attributes = {})
    @template.content_tag :li do
      @template.link_to text, url_for(page), attributes
    end
  end

  def page_span(page, text, attributes = {})
    @template.content_tag :li, :class => 'active' do
      @template.link_to text, url_for(page), attributes
    end
  end
end
