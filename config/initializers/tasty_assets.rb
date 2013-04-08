#
TASTY_ASSETS = YAML.load(File.open(File.join(Rails.root, 'config/assets.yml'))).symbolize_keys!
