require 'scenic/statements/view_statements'
require 'scenic/statements/function_statements'

module Scenic
  # Methods that are made available in migrations for managing Scenic views.
  module Statements
    include ViewStatements
    include FunctionStatements
  end
end
