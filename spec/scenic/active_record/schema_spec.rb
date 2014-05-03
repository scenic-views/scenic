require 'spec_helper'
require 'scenic/active_record/schema'

class View < ActiveRecord::Base
end

describe 'Scenic::ActiveRecord::Schema' do
  describe 'create_view' do
    it 'creates a view from a file' do
      define_view :views, 1, "SELECT text 'Hello World' AS hello"

      View.connection.create_view :views, 1

      expect(View.all.pluck(:hello)).to eq ['Hello World']

      remove_generated_files
    end
  end

  def define_view(name, version, schema)
    @to_be_removed ||= []
    view_file = ::Rails.root.join('db', 'views', "#{name}_v#{version}.sql")
    @to_be_removed << view_file
    File.open(view_file, 'w') { |f| f.write(schema) }
  end

  def remove_generated_files
    @to_be_removed.each { |f| File.delete(f) }
  end
end
