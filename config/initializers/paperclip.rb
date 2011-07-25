# https://github.com/thoughtbot/paperclip/wiki/Interpolations
Paperclip.interpolates :sha1_partition do |attachment, style|
  str  = attachment.instance.id.to_s
  str += attachment.updated_at.to_i.to_s

  File.join(Digest::SHA1.hexdigest(str)[0..1], Digest::SHA1.hexdigest(str)[2..3])
end
