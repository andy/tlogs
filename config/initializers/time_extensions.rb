
class Time
  # возвращает true если даты - один день
  def same_day?(time)
    self.to_date == time.to_date
  end
  
  def today?
    self.to_date == Date.today
  end
  
  def to_timestamp_s
    "#{mday} #{month.to_rmonth} #{year}, #{hour}:#{min}"
  end
  
  # Time.now.distance_between_in_words(1.year.ago, ' спустя')
  def distance_between_in_words(dst, postfix = nil)
    seconds = (self.to_i - dst.to_i).abs
    case seconds
    when 0..60:
      "только что"
    when 1.minute..1.hour:
      "#{(seconds/1.minute).pluralize("минуту", "минуты", "минут", true)}#{postfix}"
    when 1.hour..1.day:
      "#{(seconds/1.hour).pluralize("час", "часа", "часов", true)}#{postfix}"
    when 1.day..1.week:
      "#{(seconds/1.day).pluralize("день", "дня", "дней", true)}#{postfix}"
    when 1.week..1.month:
      "#{(seconds/1.week).pluralize("неделю", "недели", "недель", true)}#{postfix}"
    else
      "#{(seconds/1.month).pluralize("месяц", "месяца", "месяцев", true)}#{postfix}"
    end
  end
end
