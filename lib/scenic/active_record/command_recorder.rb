module Scenic
  module ActiveRecord
    module CommandRecorder
      def create_view(*args)
        record(:create_view, args)
      end

      def invert_create_view(args)
        [:drop_view, args]
      end
    end
  end
end
