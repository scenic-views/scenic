class CreateViews < ActiveRecord::Migration
  def change
    create_view :greetings
  end
end
