module ConsoleHelper
  def bootstrap_paginate collection
    content_tag :div, :class => 'pagination pagination-centered' do
      content_tag :ul do
        will_paginate collection, :container => false, :renderer => 'BootstrapLinkRenderer'
      end
    end
  end
end