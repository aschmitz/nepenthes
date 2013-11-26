config_path = "#{Rails.root.to_s}/config/auth.yml"

config = false
if File.exists?(config_path)
  config = YAML.load_file(config_path)
end

AUTH_CONFIG = config
