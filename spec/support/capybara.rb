require 'capybara/rspec'
require 'capybara/rails'
#require 'selenium-webdriver'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
#  Capybara.javascript_driver = :poltergeist
#  Capybara.javascript_driver = :poltergeist_debug

  Capybara.register_driver(:poltergeist) do |app|
    Capybara::Poltergeist::Driver.new app, js_errors: true, timeout: 180
  end

  
  config.include Capybara::DSL, type: [:request,:feature]
end
