# https://github.com/thoughtbot/paperclip/wiki/Interpolations
Paperclip.interpolates :sha1_partition do |attachment, style|
  str  = attachment.instance.id.to_s

  # Дата, когда должен был произойти перезод с летнего времени
  # >> Time.parse("30-10-2011 02:00:00 +0400").to_i
  # => 1319925600
  #
  # Дата, когда на серверах было произведено обновление софта, отменившего летний переход
  # >> Time.parse("21-11-2011 08:22:19 +0300").to_i
  # => 1321852939
  if attachment.updated_at.to_i > 1319925600 && attachment.updated_at.to_i < 1321852939
    str += (attachment.updated_at.to_i + 1.hour.to_i).to_s
  else
    str += attachment.updated_at.to_i.to_s
  end

  File.join(Digest::SHA1.hexdigest(str)[0..1], Digest::SHA1.hexdigest(str)[2..3])
end
