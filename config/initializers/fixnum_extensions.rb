class Fixnum
  def to_rwday
    %w( понедельник вторник среда четверг пятница суббота воскресенье )[self.to_i - 1]
  end
  
  def to_rmonth
    %w( января февраля марта апреля мая июня июля августа сентября октября ноября декабря )[self.to_i - 1]    
  end

  def to_rmonth_s
    %w( январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь )[self.to_i - 1]    
  end
  
  # Переворачивает адресацию в страницах. Первая становится последней, последняя - первой
  def reverse_page(total)
    return total + 1 - self.to_i if self.to_i > 0 && self.to_i <= total
    1
  end
  
  # Возвращает количетсво страниц если текущее число - общее количество записей, например:
  # Entry.count.to_pages
  def to_pages(per_page = 15)
    (self.to_i / per_page.to_f).ceil
  end

  # в булеан
  def to_b
    !!self.to_i
  end
end