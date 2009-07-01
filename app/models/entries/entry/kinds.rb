class Entry
  KINDS = {
    :any => { :select => 'все записи', :singular => 'спросить при добавлении', :filter => '1=1', :order => 1 },
    :text => { :select => 'текстовые', :singular => 'текст', :filter => 'entry_type = "TextEntry"', :order => 2 },
    :link => { :select => 'ссылки', :singular => 'ссылка', :filter => 'entry_type = "LinkEntry"', :order => 3 },
    :quote => { :select => 'цитаты', :singular => 'цитата', :filter => 'entry_type = "QuoteEntry"', :order => 4 },
    :image => { :select => 'картинки', :singular => 'картинка', :filter => 'entry_type = "ImageEntry"', :order => 5 },
    :video => { :select => 'видео', :singular => 'видео', :filter => 'entry_type = "VideoEntry"', :order => 6 },
    :convo => { :select => 'диалоги', :singular => 'диалог', :filter => 'entry_type = "ConvoEntry"', :order => 7 },
    :song => { :select => 'песни', :singular => 'песня', :filter => 'entry_type = "SongEntry"', :order => 8 },
    :code => { :select => 'программные коды', :singular => 'программный код', :filter => 'entry_type = "CodeEntry"', :order => 9 }
  }
  KINDS_FOR_SELECT = KINDS.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:select], k.to_s] }
  KINDS_FOR_SELECT_SIGNULAR = KINDS.sort_by { |obj| obj[1][:order] }.map { |k,v| [v[:singular], k.to_s] }
end