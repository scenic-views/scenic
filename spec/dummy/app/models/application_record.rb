if Rails::VERSION::STRING >= "5.0.0"
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
