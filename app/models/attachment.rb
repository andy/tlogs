# encoding: utf-8
# == Schema Information
# Schema version: 20110816190509
#
# Table name: attachments
#
#  id           :integer(4)      not null, primary key
#  entry_id     :integer(4)      default(0), not null, indexed
#  content_type :string(255)
#  filename     :string(255)     default(""), not null
#  size         :integer(4)      default(0), not null
#  type         :string(255)
#  metadata     :string(255)
#  parent_id    :integer(4)      indexed
#  thumbnail    :string(255)
#  width        :integer(4)
#  height       :integer(4)
#  user_id      :integer(4)      default(0), not null
#
# Indexes
#
#  index_attachments_on_entry_id   (entry_id)
#  index_attachments_on_parent_id  (parent_id)
#

class Attachment < ActiveRecord::Base
  ## included modules & attr_*
  serialize :metadata, Hash


  ## associations
  belongs_to :entry
  belongs_to :user


  ## plugins
  has_attachment :storage => :file_system, :max_size => 7.megabytes, :resize_to => '800x4000>', :thumbnails => { :thumb => '200x1500>', :tlog => '420x4000>' }, :file_system_path => 'public/assets/att'
  validates_as_attachment


  ## scopes
  ## validations
  validates_presence_of :entry_id
  validates_presence_of :user_id


  ## callbacks
  before_create do |att|
    begin
      # находим соответсвующий обработчик для закаченного файла
      require 'mime/types'

      mime_type = MIME::Types.type_for(att.full_filename).first

      # set the content-type based on what mime says
      att.content_type = mime_type.content_type

      # set the klass type from mime
      klass_type = mime_type.media_type.capitalize + 'Attachment'
      att[:type] = klass_type if %w( AudioAttachment ImageAttachment ).include?(klass_type)
    rescue
    end
  end


  ## class methods
  ## public methods
  def full_filename(thumbnail = nil)
    file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path]
    File.join(Rails.root, file_system_path, tasty_attachment_path(filename), "#{id}_#{user_id}_#{entry_id}_" + thumbnail_name_for(thumbnail))
  end
  
  def tasty_attachment_path(filename)
    File.join(Digest::SHA1.hexdigest(filename)[0..1], Digest::SHA1.hexdigest(filename)[2..3])
  end


  ## private methods  
end

class AudioAttachment < Attachment
  
  # достает ArtWork картинку которая утсанавливается в iTunes
  def artwork
    Mp3Info.open(self.full_filename) do |mp3|
      (mp3.tag2.PIC || mp3.tag2.APIC).unpack('Z*xa*')[1] rescue nil
    end
  rescue
    nil
  end
  
  protected
    def load_metadata
      mp3 = Mp3Info.open self.full_filename
      self.metadata = { :title => mp3.tag.title || mp3.tag2.TIT1 || mp3.tag2.TIT2 || '',
                    :album => mp3.tag.album || mp3.tag2.TALB || '',
                    :artist => mp3.tag.artist || mp3.tag2.TPE1 || mp3.tag2.TPE2 || '' 
                  }
    end
end

class ImageAttachment < Attachment
  has_attachment :storage => :file_system, :max_size => 7.megabytes, :resize_to => '800x4000>', :thumbnails => { :thumb => '200x1500>', :tlog => '420x4000>' }, :file_system_path => 'public/assets/att', :content_type => :image

  # validate do |attachment|
  #   errors.add_to_base("файл должен быть изображением в формате jpg, png, gif или bpm.") and return false unless attachment.image?
  #   
  #   true
  # end
end
