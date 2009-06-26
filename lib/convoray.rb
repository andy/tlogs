
module Convoray
  def scan(convo)
    persons = []
    last_person_to_talk = nil
    returning [] do |new_text|
      convo.split("\n").each do |line|
        # строчка c автором
        if match = line.match(/^([^ :][^:]{0,30})?:(.*)$/u) || match = line.match(/^(<[^>]+>)(.*)$/u)
          last_person_to_talk = match[1] 
          persons.push(last_person_to_talk) unless persons.include?(last_person_to_talk)
          text = match[2] || ''
          new_text << "<div class='person_#{persons.index(last_person_to_talk)+1}'><span>#{ERB::Util.html_escape last_person_to_talk}:</span> #{ERB::Util.html_escape text}</div>"
        elsif last_person_to_talk
          new_text << "<div class='person_#{persons.index(last_person_to_talk)+1}'> #{ERB::Util.html_escape line.strip}</div>"
        else
          new_text << ERB::Util.html_escape(line.strip)
        end
      end
    end.join("\n")
  end

  module_function :scan
end