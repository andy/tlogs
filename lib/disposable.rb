#
# Disposable email validations
#
# http://undisposable.org
#
require 'net/http'
require 'uri'
require 'json'

DISPOSABLE_DOMAINS = %w(
  mailspeed.ru
  jetable.org
  spamfree24.org
  tempemail.net
  yopmail.com
  sharklasers.com
  guerrillamailblock.com
  guerrillamail.com
  guerrillamail.net
  guerrillamail.biz
  guerrillamail.org
  guerrillamail.de
  rtrtr.com
  10minutemail.com
  rppkn.com  
  mailcatch.com
  maillses.allowed.org
  mails.twilightparadox.com
  amail.shop.tm
  tradermail.info
  2ch.so
  shitmail.me
  mailforspam.com
  mailinator.com
  binkmail.com
  safetymail.info
  thisisnotmyrealemail.com
  bobmail.info
  spamherelots.com
  devnullmail.com
  obobbo.com
  frapmail.com
  SendSpamHere.com
  SpamThisPlease.com
  suremail.info
  zippymail.info
  chammy.info
  bobmail.info
  dreamsbook.org
  summer-breath.com
  dnset.com
  ddns.mobi
  acmetoy.com
  ikwb.com
  dynamicdns.co.uk
  MyNetAV.ORG
  MyNetAV.NET
  MyLFTV.COM
  dynssl.COM
  dns-stuff.com
  changeip.org
  mysecondarydns.com
  changeip.net
  dyndns.pro
  myFtp.name
  ProxyDNS.com
  dns-dns.com
  lflink.COM
  LfLinkup.ORG
  LfLinkup.NET
  LfLinkup.COM
  dnsrd.com
  PORTRELAY.COM
  trickip.ORG
  trickip.NET
  sendsmtp.COM
  ezua.COM
  REBATESRULE.NET
  ddns.name
  changeip.name
  ns3.name
  ns2.name
  ns1.name
  mynumber.ORG
  DSMTP.COM
  3-a.net
  h1x.com
  4pu.com
  4dq.com
  25u.com
  4MyDomain.Com
  GetTrials.COM
  ddns.us
  dynamicdns.org.uk
  dynamicdns.me.uk
  ddns.ms
  ddns.me.uk
  YGTO.com
  pcanywhere.NET
  OurHobby.com
  oCry.com
  AlmostMy.COM
  ns01.us
  ns02.us
  dns1.us
  dns2.us
  BigMoney.biz
  Got-Game.org
  ninth.biz
  sixth.biz
  eSMTP.biz
  port25.biz
  moneyhome.biz
  wwwhost.biz
  ftpserver.biz
  gr8name.biz
  gr8domain.biz
  myWWW.biz
  ftp1.biz
  eDNS.biz
  dhcp.biz
  www1.biz
  freeWWW.biz
  sexxxy.biz
  xxxy.biz
  ns02.biz
  ns01.biz
  dynamicDNS.biz
  myDDNS.com
  freeddns.com
  freeWWW.info
  xxxy.info
  toh.info
  Squirly.info
  myZ.info
  myPicture.info
  myMom.info
  myDad.info
  myFTP.info
  ns02.info
  ns01.info
  ddns.info
  freeTCP.com
  ServeUser.com
  ServeUsers.com
  americanunfinished.com
  sellClassics.com
  oTZO.com
  MrsLove.com
  IsASecret.com
  MrFace.com
  VizVaz.com
  qHigh.com
  qpoe.com
  JetOS.com
  FAQServ.com
  itsAOL.com
  Jkub.com
  xxuz.com
  InstantHQ.com
  ItemDB.com
  FartIT.com
  my03.com
  zyns.com
  dns05.com
  dns04.com
  x24HR.com
  MrBonus.com
  MrBasic.com
  jungleheart.com
  justdied.com
  toythieves.com
  organiccrap.com
  mefound.com
  sexidude.com
  2waky.com
  yourtrap.com
  youdontcare.com
  wha.la
  onedumb.com
  1dumb.com
  dumb1.com
  zzux.com
  wikaba.com
  compress.to
  longmusic.com
  epac.to
  dynamic-dns.net
  temporamail.com
)

module Disposable
  def is_disposable_email?(email)
    DISPOSABLE_DOMAINS.each do |domain|
      return true if email.downcase.ends_with?('@' + domain.downcase)
      return true if email.downcase.ends_with?('.' + domain.downcase)
    end
    
    return false

    begin
      req = Net::HTTP::Get.new("/services/json/isDisposableEmail/?email=#{email}")
      res = Net::HTTP.start('www.undisposable.net') { |http| http.request(req) }

      if res.is_a?(Net::HTTPOK)
        json = JSON.parse(res.body)
        return true if json['stat'] == 'ok' && json['email']['isdisposable'] == true
      end

      false
    rescue Exception => ex
      HoptoadNotifier.notify(
        :error_class    => ex.class.name,
        :error_message  => "#{ex.class.name}: #{ex.message}",
        :backtrace      => ex.backtrace,
        :parameters     => { :email => email }
      )
      
      false
    end
  end

  module_function :is_disposable_email?
end