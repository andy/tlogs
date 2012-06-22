#!/usr/bin/env script/runner

entries = Entry.find :all, :conditions => 'data_part_1 LIKE "%mainnika loves afeena%" AND id >= 9717780', :order => 'id DESC', :limit => 10000

entries.each do |entry|
  puts entry.id
  puts entry.data_part_1
  puts entry.data_part_2
  entry.destroy
end

