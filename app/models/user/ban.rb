class User
  BAN_AC_DURATIONS = {
    'unban'   => 0,
    '2d'      => 2.days,
    '2w'      => 2.weeks,
    '2m'      => 2.months
  }

  # ban on AC (anonymous comments)
  def ban_ac!(entry, comment, duration)
    d = BAN_AC_DURATIONS[duration] rescue 2.months
    self.update_attribute(:ban_ac_till, d.zero? ? nil : d.from_now)
  end

  def unban_ac!
    self.update_attribute(:ban_ac_till, nil)
  end

  def unban_c!
    self.update_attribute(:ban_c_till, nil)
  end

  def is_ac_banned?
    ban_ac_till && ban_ac_till > Time.now
  end

  def is_c_banned?
    ban_c_till && ban_c_till > Time.now
  end

  def ac_ban_days_left
    return 0 unless self.is_ac_banned?

    seconds_left = self.is_ac_banned? ? (self.ban_ac_till - Time.now) : 0
    ((seconds_left + 1.day) / 1.day).ceil.to_i
  end

  def c_ban_days_left
    return 0 unless self.is_c_banned?

    seconds_left = self.is_c_banned? ? (self.ban_c_till - Time.now) : 0
    ((seconds_left + 1.day) / 1.day).ceil.to_i
  end
end
