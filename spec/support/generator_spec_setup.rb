require "rspec/rails"
require "ammeter/rspec/generator/example.rb"
require "ammeter/rspec/generator/matchers.rb"
require "ammeter/init"

RSpec.configure do |config|
  config.before(:example, :generator) do
    fake_rails_root = File.expand_path("../../tmp", __dir__)
    fake_rails_root_pathname = Pathname.new(fake_rails_root)
    allow(Rails).to receive(:root).and_return(fake_rails_root_pathname)
    allow(Scenic).to receive(:root_path).and_return(fake_rails_root_pathname)

    destination fake_rails_root
    prepare_destination
  end
end
