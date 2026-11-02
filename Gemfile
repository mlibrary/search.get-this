source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "sinatra"
gem "faraday-follow_redirects"
gem "puma"
gem "yabeda-puma-plugin"
gem "yabeda-prometheus"
gem "activesupport" # in here because of timezone support
gem "sinatra-flash"
gem "rackup"
gem "ostruct"

gem "alma_rest_client",
  git: "https://github.com/mlibrary/alma_rest_client",
  tag: "alma_rest_client/v2.2.0"

# In order to get rspec to work for ruby 3.3. Maybe later see if it's still necessary
gem "net-smtp", require: false

group :development do
  gem "sinatra-contrib"
end
group :development, :test do
  gem "standard"
  gem "debug"
  gem "rack-test"
  gem "rspec"
  gem "webmock"
  gem "simplecov"
  gem "climate_control"
end
