module AssetGluer
  class JavascriptFile < AssetFile
    def self.dir
      File.join(AssetGluer.asset_dir, 'javascripts')
    end

    def process
      contents = File.read(@absolute_path)

      contents = process_with_coffee(contents) if @absolute_path.ends_with?('.coffee')
      
      contents
    end
    
    def self.process(contents)
      # uglifier requires special care, disabled
      # contents = self.process_with_uglifier(contents) if Rails.env.production?
      
      contents
    end

    def self.process_with_uglifier(contents)
      Uglifier.compile contents, TASTY_ASSETS[:compressor_options].symbolize_keys!
    end
    
    protected
      def process_with_coffee(contents)
        Rails.cache.fetch "gluer:js:coffee:#{Digest::SHA1.hexdigest(contents)}", :expires_in => 1.day do
          IO.popen 'coffee -bsc', 'r+' do |io|
            io.write(contents)
            io.close_write
            io.read
          end
        end
      end
      
  end
end