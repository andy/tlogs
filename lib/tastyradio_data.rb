require 'net/http'
require 'uri'

# http://stream12.radiostyle.ru:8012/status2.xsl?mount=/tastyradio_1
# http://radio.tlogs.ru:8000/status2.xsl

module TastyradioData
  def fetch
    begin
      require 'hpricot'

      req = Net::HTTP::Get.new("/status2.xsl")
      res = Net::HTTP.start('radio.tlogs.ru', 8000) { |http| http.request(req) }

      if res.is_a?(Net::HTTPOK)
        doc = Hpricot.XML(res.body.to_s)
        status = (doc/"//pre").first.html.split("\n").last.split(',')

        result = {
          :online     => 0,
          :song       => 'Не удалось получить данные'
        }

        onum = 5
        (status.length / 6).times do |i|
          onum += status[(i*6) + 3].to_i
        end

        offset = (status.length / 6) - 1
        if offset >= 0
          data = status[(offset*6)...((offset + 1) * 6)]
          result[:online] = data[3]
          result[:song]   = data[5].strip.gsub(/^\-\s+/, '').gsub(/\s+\-$/, '')
        
          result[:song] = 'неизвестный трек' if result[:song] && result[:song] == '-'
        end

        result[:online] = onum if onum > 0
        
        return result
      end

      nil
    # rescue
    # 
    #   nil
    end
    
  end
  
  module_function :fetch
end
