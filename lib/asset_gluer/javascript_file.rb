module AssetGluer
  class JavascriptFile < AssetFile

    def self.dir
      ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR rescue "#{AssetGluer.asset_dir}/javascripts"
    end

    def process
      File.open(@absolute_path).read
    end
  end
end