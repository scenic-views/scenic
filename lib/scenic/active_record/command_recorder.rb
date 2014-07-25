require "rails"

module Scenic
  module ActiveRecord
    module CommandRecorder
      def create_view(*args)
        record(:create_view, args)
      end

      def drop_view(*args)
        record(:drop_view, args)
      end

      def update_view(*args)
        record(:update_view, args)
      end

      private

      def invert_create_view(args)
        [:drop_view, args]
      end

      def invert_drop_view(args)
        [:create_view, args]
      end
    end
  end
end

ActiveRecord::Migration::CommandRecorder.send :include, Scenic::ActiveRecord::CommandRecorder
