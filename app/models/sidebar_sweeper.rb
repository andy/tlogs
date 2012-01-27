# encoding: utf-8
class SidebarSweeper < ActionController::Caching::Sweeper
  observe SidebarElement, SidebarSection
  
  def after_create(element)
    expire_sidebar(element)
  end
  
  def after_update(element)
    expire_sidebar(element)
  end
  
  def after_destroy(element)
    expire_sidebar(element)
  end
  
  private
    def expire_sidebar(element)
      section = element.section if element.is_a?(SidebarElement)
      section = element if element.is_a?(SidebarSection)

      expire_fragment("#{current_service.try(:domain) || ''}/#{section.user.url}/sidebar_sections") unless section.blank?
    end  
end