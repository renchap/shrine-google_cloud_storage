Gem::Specification.new do |gem|
  gem.name          = "shrine-google_cloud_storage"
  gem.version       = "0.1.0"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Google Cloud Storage storage for Shrine."
  gem.homepage     = "https://github.com/renchap/shrine-google_cloud_storage"
  gem.authors      = ["Renaud Chaput"]
  gem.email        = ["renchap@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "shrine-google_cloud_storage.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", "~> 2.0"
  gem.add_dependency "google-api-client", "~> 0.13.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
