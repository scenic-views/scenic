require "ammeter/rspec/generator/example.rb"
require "ammeter/rspec/generator/matchers.rb"

RSpec.configure do |config|
  config.before(:example, :generator) do
    destination File.expand_path("../../../tmp", __FILE__)
    prepare_destination
  end
end
