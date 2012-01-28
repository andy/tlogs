# encoding: utf-8
# == Schema Information
# Schema version: 20110816190509
#
# Table name: entries
#
#  id               :integer(4)      not null, primary key, indexed => [is_mainpageable]
#  user_id          :integer(4)      default(0), not null, indexed, indexed => [is_private, created_at]
#  data_part_1      :text
#  data_part_2      :text
#  data_part_3      :text
#  type             :string(0)       default("TextEntry"), not null, indexed
#  is_disabled      :boolean(1)      default(FALSE), not null, indexed
#  created_at       :datetime        not null, indexed, indexed => [user_id, is_private]
#  metadata         :text
#  comments_count   :integer(4)      default(0), not null
#  updated_at       :datetime
#  is_voteable      :boolean(1)      default(FALSE), indexed
#  is_private       :boolean(1)      default(FALSE), not null, indexed, indexed => [user_id, created_at]
#  cached_tag_list  :text
#  is_mainpageable  :boolean(1)      default(TRUE), not null, indexed, indexed => [id]
#  comments_enabled :boolean(1)      default(FALSE), not null
#
# Indexes
#
#  index_entries_on_is_disabled             (is_disabled)
#  index_entries_on_type                    (type)
#  index_entries_on_is_mainpageable         (is_mainpageable)
#  index_entries_on_user_id                 (user_id)
#  index_entries_on_is_private              (is_private)
#  index_entries_on_is_voteable             (is_voteable)
#  index_entries_on_created_at              (created_at)
#  index_entries_on_uid_pvt_cat             (user_id,is_private,created_at)
#  index_entries_on_is_mainpageable_and_id  (is_mainpageable,id)
#

#
# Анонимная текстовая запись
#   data_part_1 - текст
#   data_part_2 - заголовок

class AnonymousEntry < Entry
  ANONYMOUS_COMMENTS_DEPLOY_TIME = Time.parse("Tue Jul 07 10:30:00 +0400 2009")
  
  validates_presence_of :data_part_1, :on => :save
  validates_presence_of :data_part_2, :on => :save, :message => 'это обязательное поле'
  validates_length_of :data_part_1, :within => 1..ENTRY_MAX_LENGTH, :on => :save, :too_long => 'это поле слишком длинное'
  validates_length_of :data_part_2, :within => 2..140, :on => :save, :too_long => 'это поле слишком длинное'


  BAD_WORDS = %w(хуи хуиня хуище хуило хер херня нахуи нихуя хуя похуям xuy иух нахуя похуи пох похер
                ебать ебло ебало ебаться ебут ебанул ебануть ебли выебать ебнуть
                иоба еба ебануться ебануть ебнутыи ебнутая ебнутые ебал
                подеб подеб подьебал подебал подиебал подибал
                пизда пиздец ваниль ванильная
                тупои тупая тупые тупыми
                сука суки сучка
                бля блядь блять
                мудак обмудок мудила мудило мудик
                пидарас пидор педик
                говно
                срань сраныи сраная
                трахать трахнуть трахаться
                егэ
                сопли
                троллинг тролль трололо
                школота школоло
                член вагина
                fuck dick fucking fcuk suck sucking fuxx sex eblya
                дрянь дряни быдло гопота гопник
                )

  validates_each :data_part_1, :data_part_2 do |record, attr, value|
    value.split(/(,|\ |:|\.)/).each do |word|      
      word = word.mb_chars.downcase.gsub(/(\s|\d)+/, '').squeeze
      
      next if word.blank?
      
      word = word.mb_chars \
              .sub('ё', 'е') \
              .sub('й', 'и') \
              .sub('o', 'о') \
              .sub('y', 'у') \
              .sub('e', 'е') \
              .sub('a', 'а') \
              .sub('c', 'с') \
              .sub('m', 'м') \
              .sub('b', 'б') \
              .sub('p', 'р') \
              .sub('ъ', 'ь') \
              .sub('i', 'и') 

      if BAD_WORDS.include?(word)
        record.errors.add(attr, 'Бранные слова запрещены. В случае использования нецензурной лексики<br/> или намека на неё, Ваш тлог может быть <b>удален</b>.')
        break
      end
    end unless value.blank?    
  end

  def entry_russian_dict; { :who => 'анонимка', :whom => 'анонимку' } end
  def excerpt
    if self.data_part_2.to_s.length > 0 
      self.data_part_2.to_s.truncate(150).to_s
    else
      self.data_part_1.to_s.truncate(150).to_s
    end
  end
  def self.new_from_bm(params)
    content = params[:c].strip if params[:c]
    content ||= ''
    title = params[:title].strip if params[:title]
    # разбиваем на две новые части если нет заголовка, но есть содержимое
    title, content = content.split("\n", 2) if title.blank? && !content.blank?
    title = title.truncate(50) if title
    content += "\n<a href='#{params[:url]}'>отсюда</a>" if content
    self.new :data_part_1 => content, :data_part_2 => title
  end
end
