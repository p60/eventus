source "https://rubygems.org"

gemspec

group :development do
  gem 'rake'
  gem 'rspec'
  gem 'uuid'
  gem 'mongo'
  gem 'bson_ext'
  gem 'redis'

  gem 'kyotocabinet-ruby', :platforms => [:mri, :rbx] unless ENV['TRAVIS']
end
