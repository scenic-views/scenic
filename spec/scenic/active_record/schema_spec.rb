require 'spec_helper'
require 'scenic/active_record/schema'

class View < ActiveRecord::Base
end

describe 'Scenic::ActiveRecord::Schema' do
  describe 'create_view' do
    it 'creates a view from a file' do
      View.connection.create_view :views

      expect(View.all.pluck(:hello)).to eq ['Hello World']
    end
  end
end
