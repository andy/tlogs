class AdminController < ApplicationController
  before_filter :require_current_site, :require_confirmed_current_user, :require_confirmed_current_site
  
  before_filter :require_admin

  def disable
    current_site.async_disable!

    render :update do |page|
      page.call 'window.location.reload'
    end
  end
  
  def destroy
    current_site.async_destroy!
  end
  
  # remove all entries from mainpage, alter user
  def demainpage
    # block user from ever appearing on main page again
    current_site.is_mainpageable = false
    current_site.save!
    
    # block all old entries from mainpage
    current_site.entries.paginated_each do |entry|
      if entry.is_mainpageable?
        # remove from mainpage
        entry.is_mainpageable = false

        # also, remove from all lists
        # entry.is_great        = false
        # entry.is_good         = false
        # entry.is_everything   = false

        entry.save!
      end
    end

    render :update do |page|
      page.toggle('sidebar_admin_demainpage', 'sidebar_admin_enablemainpage')
    end
  end
  
  # turn that back, but do not alter older entries 
  def enablemainpage
    current_site.is_mainpageable = true
    current_site.save
    
    render :update do |page|
      page.toggle('sidebar_admin_demainpage', 'sidebar_admin_enablemainpage')
    end
  end  
end