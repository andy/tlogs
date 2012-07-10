task "resque:setup" => :environment do
  if Rails.env.production?
    require 'newrelic_rpm'
    NewRelic::Agent.manual_start
  end
end