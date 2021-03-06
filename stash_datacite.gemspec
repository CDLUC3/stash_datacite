$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'stash_datacite/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_datacite'
  s.version     = StashDatacite::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDLUC3/stash_datacite'
  s.summary     = 'An engine for working with the DataCite schema in Stash.'
  s.description = 'An engine for working with the DataCite schema in Stash.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2.4'
  s.add_dependency 'responders', '~> 2.0'
  s.add_dependency 'leaflet-rails'
  s.add_dependency 'kaminari'
  s.add_dependency 'rubyzip', '>= 1.0.0'

  s.add_dependency 'datacite-mapping', '~> 0.2', '>= 0.2.5'
  s.add_dependency 'stash-wrapper', '~> 0.1', '>= 0.1.11.1'

  # TODO: remove this once the EZID calls are out of StashDatacite
  s.add_dependency 'stash_ezid_datacite', '~> 0.1'

  s.add_development_dependency 'mysql2', '~> 0.3'

  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rspec-rails', '~> 3.5'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'chromedriver-helper'
  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'sauce_whisk'
end
