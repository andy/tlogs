class OptimizeEntriesTable < ActiveRecord::Migration
  def self.up
    # >> Entry.count :group => 'type'
    # => #<OrderedHash {"AnonymousEntry"=>2944, "QuoteEntry"=>73036, "ImageEntry"=>122969, "LinkEntry"=>11600, "ConvoEntry"=>7296, "TextEntry"=>238388, "SongEntry"=>12602, "CodeEntry"=>294, "VideoEntry"=>15553}>
    execute 'ALTER TABLE entries MODIFY type ENUM ("AnonymousEntry", "QuoteEntry", "ImageEntry", "LinkEntry", "ConvoEntry", "TextEntry", "SongEntry", "CodeEntry", "VideoEntry") NOT NULL DEFAULT "TextEntry"'
  end

  def self.down
  end
end
