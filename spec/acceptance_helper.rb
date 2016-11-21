require "bundler"

ENV["RAILS_ENV"] = "test"

RSpec.configure do |config|
  config.around(:each) do |example|
    Dir.chdir("spec/dummy") do
      example.run
    end
  end

  config.before(:suite) do
    Dir.chdir("spec/dummy") do
      system <<-CMD
        git init 1>/dev/null &&
        git add -A &&
        git commit --no-gpg-sign --message 'initial' 1>/dev/null
      CMD
    end
  end

  config.after(:suite) do
    Dir.chdir("spec/dummy") do
      if Rails::VERSION::MAJOR >= 5
        system <<-CMD
          rake db:drop db:create db:environment:set &&
          git add -A &&
          git reset --hard HEAD 1>/dev/null &&
          rm -rf .git/ 1>/dev/null
        CMD
      else
        system <<-CMD
          rake db:drop db:create &&
          git add -A &&
          git reset --hard HEAD 1>/dev/null &&
          rm -rf .git/ 1>/dev/null
        CMD
      end
    end
  end
end
