class Entry
  # fix visibility for entries that are over limit
  before_validation do |entry|
    entry.visibility = 'public' if entry.id.nil? && !entry.author.is_allowed_visibility?(entry.visibility)

    entry.visibility = 'public' if %w(mainpageable voteable).include?(entry.visibility) && entry.unwanted_content?
  end

  # видимость записи, @entry.visibility - это виртуальное поле, options: 0 - is_voteable, 1 - is_mainpageable, 2 - is_private
  VISIBILITY = {
    :private => { :new => 'закрытая - не увидит никто, кроме вас', :edit => 'закрытая - не увидит никто, кроме вас', :options => [false, false, true], :order => 1 },
    :public => { :new => 'открытая - видна всем только в вашем тлоге', :edit => 'открытая - видна всем только в вашем тлоге', :options => [false, false, false], :order => 2 },
    :mainpageable => { :new => 'публичная - видна всем и попадает в прямой эфир', :edit => 'публичная - видна всем и попадает в прямой эфир', :options => [false, true, false], :order => 3 },
    :voteable => { :new => 'публичная с голосованием', :edit => 'публичная с голосованием', :options => [true, true, false], :order => 4 }
  }
  VISIBILITY_FOR_SELECT_NEW = VISIBILITY.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:new], k.to_s] }
  VISIBILITY_FOR_SELECT_EDIT = VISIBILITY.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:edit], k.to_s] }

  # Виртуальный атрибут visibility позволяет нам заботиться о всех составляющих видимости записи практически через одну функцию
  def visibility
    VISIBILITY.find { |v| v[1][:options] == [self.is_voteable?, self.is_mainpageable?, self.is_private?] }[0].to_s rescue :public
  end

  def visibility=(kind)
    kind ||= 'private'
    kind = 'private' unless VISIBILITY.keys.map(&:to_s).include?(kind)

    options = VISIBILITY[kind.to_sym][:options]

    # если is_voteable стоит в true - ничего нельзя имзенить...
    if !self.is_voteable? || self.new_record?
      self.is_voteable, self.is_mainpageable, self.is_private = options
      # 0 - is_voteable, выставляется только если пользователю разрешено это делать и только на новую запись
      self.is_voteable = true if options[0] && self.new_record?
      # is_mainpageable сбрасывается, если у пользователя отсутствует этот флаг
      self.is_mainpageable = false if self.author && !self.author.is_mainpageable?
    end
  end

  def unwanted_content?
    contents = [self.data_part_1, self.data_part_2, self.data_part_3].compact.join("\n")

    bads = [
      'testkub.ru',
      'magicwish.ru',
      'lovetree.rulezz.ru',
      'lleo.aha.ru/test/vicont',
      'rupoll.com',
      'life-sense.ru',
      'alolo.ru',
      'chedelat.ru',
      'nefart.ru',
      'formspring.me/',
      'beon.ru/test',
      'summer-breath.com',
      'dreamsbook.org',
      'uath.org/nev',
      'sprashivai.ru',
      'florist.ru',
      'freeflashtoys.com',
      'viewy.ru',
      'media.tumblr.com',
      'rghost.net',
      'qip.ru/test',
      'liveinternet.ru',
      'diary.ru',
      'jokesland.net.ru',
      'rg.ru/test',
      'rutvit.ru',
      'godudu.com',
      'jujuju.ru',
      'blogspot.com',
      'liveinternet.ru',
      'radikal.ru',
      'apikabu.ru',
      '9gag.com',
      'futubra.com',
      'caricatura.ru',
      '77.120.199.195',
      'twitter.com',
      'clck.ru',
      'Кредит наличными',
      'mainnika loves afeena'
      ]

    bads.find { |bad| contents.include?(bad) } ? true : false
  end
end
