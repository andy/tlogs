require 'tempfile'

$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
puts $LOAD_PATH
require 'technoweenie/attachment_fu'

Tempfile.class_eval do
  def make_tmpname(basename, n)
     ext = nil
     n ||= 0
     sprintf("%s%d-%d%s", basename.to_s.gsub(/\.\w+$/) { |s| ext = s; '' }, $$, n, ext)
   end
end

require 'attachment_fu/lib/geometry'
ActiveRecord::Base.send(:extend, Technoweenie::AttachmentFu::ActMethods)
Technoweenie::AttachmentFu.tempfile_path = ATTACHMENT_FU_TEMPFILE_PATH if Object.const_defined?(:ATTACHMENT_FU_TEMPFILE_PATH)
FileUtils.mkdir_p Technoweenie::AttachmentFu.tempfile_path

$:.unshift(File.dirname(__FILE__) + '/vendor')
