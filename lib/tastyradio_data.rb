require 'net/http'
require 'uri'

# http://stream12.radiostyle.ru:8012/status2.xsl?mount=/tastyradio_1
# http://radio.tlogs.ru:8000/status2.xsl

module TastyradioData
  def fetch
    begin
      req = Net::HTTP::Get.new("/status2.xsl")
      res = Net::HTTP.start('radio.tlogs.ru', 8000) { |http| http.request(req) }

      if res.is_a?(Net::HTTPOK)
        # xsl = Iconv.iconv('utf-8', 'windows-1251', res.body).to_s
        xsl = res.body.to_s

        result = {
          :online  => 0,
          :song       => 'Не удалось получить данные'
        }
        
        result[:online] = xsl.split(',')[14] if xsl && xsl.split(',')[14]
        result[:song]   = xsl.split(',')[16] if xsl && xsl.split(',')[16]

        return result
      end

      nil
    rescue

      nil
    end
    
  end
  
  module_function :fetch
end