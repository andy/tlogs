module ConsoleHelper
  def bootstrap_paginate collection
    content_tag :div, :class => 'pagination pagination-centered' do
      content_tag :ul do
        will_paginate collection, :container => false, :renderer => 'BootstrapLinkRenderer'
      end
    end
  end

  def hide_email address
    is_admin? ? address : (address.split('@').first[0..2] + "*****@" + address.split('@').last)
  end

  def report_excerpt report
    auto_link h(report.excerpt)
  end
end
