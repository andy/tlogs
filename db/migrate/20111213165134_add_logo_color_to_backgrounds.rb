class AddLogoColorToBackgrounds < ActiveRecord::Migration
  def self.up
  	add_column :backgrounds, :gray_logo, :bool, { :default => 0, :null => false }
  end

  def self.down
  	remove_column :backgrounds, :gray_logo
  end
end
