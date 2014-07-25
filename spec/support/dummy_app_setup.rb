RSpec.configure do |config|
  config.before :each, type: :feature do
    FileUtils.rm_f('spec/dummb/db/schema.rb')
  end
end
