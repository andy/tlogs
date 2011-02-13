require 'net/http'
require 'uri'
require 'hpricot'

module Ipgeobase
  def lookup(addr)
    begin
      req = Net::HTTP::Get.new("geo?ip=#{addr}")
      res = Net::HTTP.start('ipgeobase.ru', 7020) { |http| http.request(req) }

      if res.is_a?(Net::HTTPOK)
        xml = Hpricot::XML(Iconv.iconv('utf-8', 'windows-1251', res.body).to_s)
        
        result = {}
        result[:city] = (xml / :city).first.try(:innerText)
        result[:country] = (xml / :country).first.try(:innerText)
        result[:region] = (xml / :region).first.try(:innerText)
        result[:district] = (xml / :district).first.try(:innerText)
        result[:lat] = (xml / :lat).first.try(:innerText)
        result[:lng] = (xml / :lng).first.try(:innerText)

        return result if result[:city]
      end

      nil
    rescue

      nil
    end
    
  end
  
  module_function :lookup
end