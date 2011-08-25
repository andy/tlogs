class BulkTransaction < ActiveRecord::Base
  belongs_to :transaction
  
  serialize :metadata, HashWithIndifferentAccess
  
  def valid?
    case service
    when 'smsonline'
      key = ::SETTINGS[:billing]['smsonline']['key']
      seq = %w(tid sn op phone pref txt)
      str = key + seq.map { |k| self.metadata[k] }.join

      Digest::MD5.hexdigest(str) == self.metadata[:md5]      

    else
      Rails.logger.debug "unsupported service: #{service}"

      false
    end
  end
  
  def txn_amount
    case service
    when 'smsonline'
      self.metadata[:cost].to_f      
    else
      0
    end
  end
end
