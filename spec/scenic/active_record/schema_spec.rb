require 'spec_helper'
require 'scenic/active_record/schema'

class View < ActiveRecord::Base
end

describe 'Scenic::ActiveRecord::Schema', :db do
  describe 'create_view' do
    it 'creates a view from a file' do
      with_view_definition :views, 1, "SELECT text 'Hello World' AS hello" do
        View.connection.create_view :views

        expect(View.all.pluck(:hello)).to eq ['Hello World']
      end
    end

    it 'creates a view from a specific version' do
      with_view_definition :views, 15, "SELECT text 'Hello Earth East 15' AS hello" do
        View.connection.create_view :views, 15

        expect(View.all.pluck(:hello)).to eq ['Hello Earth East 15']
      end
    end
  end

  describe 'drop_view' do
    it 'removes a view from the database' do
      with_view_definition :things, 1, "SELECT text 'Hi' AS greeting" do
        View.connection.create_view :things

        View.connection.drop_view :things

        expect(views).not_to include 'things'
      end
    end
  end

  describe 'update_view' do
    it 'updates an existing view in the database' do
      with_view_definition :views, 1, "SELECT text 'Hi' AS greeting" do
        View.connection.create_view :views
        with_view_definition :views, 2, "SELECT text 'Hello' AS greeting" do
          View.connection.update_view :views, 2

          expect(View.all.pluck(:greeting)).to eq ['Hello']
        end
      end
    end
  end

  def views
    ActiveRecord::Base.connection
      .execute('SELECT table_name FROM INFORMATION_SCHEMA.views')
      .map(&:values).flatten
  end

  def with_view_definition(name, version, schema)
    view_file = ::Rails.root.join('db', 'views', "#{name}_v#{version}.sql")
    File.open(view_file, 'w') { |f| f.write(schema) }
    yield
  ensure
    File.delete view_file
  end
end
