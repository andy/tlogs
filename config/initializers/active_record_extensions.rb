# http://rails.techno-weenie.net/tip/2005/12/23/make_fixtures
ActiveRecord::Base.class_eval do
  # person.dom_id #-> "person-5"
  # new_person.dom_id #-> "person-new"
  # new_person.dom_id(:bare) #-> "new"
  # person.dom_id(:person_name) #-> "person-name-5"
  def dom_id(prefix=nil, postfix=nil)
    display_id = new_record? ? "new" : id
    prefix = prefix.to_s.underscore
    postfix = postfix.to_s.underscore
    # prefix ||= self.class.name.underscore
    # prefix != :bare ? "#{prefix.to_s.dasherize}-#{display_id}" : display_id
    ([prefix.blank? ? nil : prefix, self.class.name.underscore, display_id, postfix.blank? ? nil : postfix].compact * '_').tr('/-.', '_')
  end
end
