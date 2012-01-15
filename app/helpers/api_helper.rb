module ApiHelper
  include ActionView::Helpers::AssetTagHelper

  def export_mentions(mentions)
    print_mentions = []
    mentions.each do |mention|
      userpic = mention.userpic? ? mention.userpic.url(:thumb16) : (mention.avatar ? mention.avatar.public_filename : image_path('noavatar.gif'))
      print_mentions.push({ 'pic' => userpic, 'url' => mention.url }) if mention.url
    end

    return {:success => 1, :x => "y2", :list => print_mentions}
  end
end