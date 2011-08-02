class PackagesController < ApplicationController
  
  def css
    files   = TASTY_ASSETS[:stylesheets][params[:name]]
    result  = AssetGluer::StylesheetFile.glue(files)

    render :text => result, :content_type => 'text/css'
  end
  
  def js
    files   = TASTY_ASSETS[:javascripts][params[:name]]
    result  = AssetGluer::JavascriptFile.glue(files)

    render :text => result, :content_type => 'text/javascript'
  end
end