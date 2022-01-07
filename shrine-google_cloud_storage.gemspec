Gem::Specification.new do |gem|
  gem.name          = "shrine-google_cloud_storage"
  gem.version       = "3.1.0"

  gem.required_ruby_version = ">= 2.6"

  gem.summary      = "Provides Google Cloud Storage storage for Shrine."
  gem.homepage     = "https://github.com/renchap/shrine-google_cloud_storage"
  gem.authors      = ["Renaud Chaput"]
  gem.email        = ["renchap@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "shrine-google_cloud_storage.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", "~> 3.0"
  gem.add_dependency "google-cloud-storage", "~> 1.6"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
  gem.add_development_dependency "http", "~> 5.0"
end
