# encoding: utf-8
module UserExtensions
  module Ban
    BAN_AC_DURATIONS = {
      'unban'   => 0,
      '2d'      => 2.days,
      '2w'      => 2.weeks,
      '2m'      => 2.months
    }
    
    extend ActiveSupport::Concern

    module InstanceMethods
      # ban on AC (anonymous comments)
      def ban_ac!(entry, comment, duration)
        d = BAN_AC_DURATIONS[duration] rescue 2.months
        self.update_attribute(:ban_ac_till, d.zero? ? nil : d.from_now)
      end

      def unban_ac!
        self.update_attribute(:ban_ac_till, nil)
      end

      def is_ac_banned?
        # not banned if empty
        return false if self.ban_ac_till.nil?

        # banned if not expired
        return true if self.ban_ac_till > Time.now

        # if expired, clear value
        unban_ac!

        false
      end
    end
  end
end