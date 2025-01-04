module Scenic
  module Adapters
    class Postgres
      # Generates a temporary object name used internally by Scenic. This is
      # used during side-by-side materialized view updates to avoid naming
      # collisions. The generated name is based on a SHA1 hash of the original
      # which ensures we do not exceed the 63 character limit for object names.
      #
      # @api private
      class TemporaryName
        # The prefix used for all temporary names.
        PREFIX = "_scenic_sbs_".freeze

        # Creates a new temporary name object.
        #
        # @param name [String] The original name to base the temporary name on.
        def initialize(name)
          @name = name
          @salt = SecureRandom.hex(4)
          @temporary_name = "#{PREFIX}#{Digest::SHA1.hexdigest(name + salt)}"
        end

        # @return [String] The temporary name.
        def to_s
          temporary_name
        end

        private

        attr_reader :name, :temporary_name, :salt
      end
    end
  end
end
