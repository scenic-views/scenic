require "rspec/rails"
require "ammeter/rspec/generator/example.rb"
require "ammeter/rspec/generator/matchers.rb"
require "ammeter/init"

RSpec.configure do |config|
  rails_root = Rails.root
  fake_rails_root = Pathname.new(File.expand_path("../../tmp", __dir__))

  config.before(:example, :generator) do
    allow(Rails).to receive(:root).and_return(fake_rails_root)

    destination fake_rails_root.to_s
    prepare_destination

    Scenic.configure do |configuration|
      configuration.definitions_path = fake_rails_root.join("db", "views")
    end
  end

  config.after(:example, :generator) do
    Scenic.configure do |configuration|
      configuration.definitions_path = rails_root.join("db", "views")
    end
  end
end
