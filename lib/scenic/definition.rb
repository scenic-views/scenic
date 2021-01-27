module Scenic
  # @api private
  class Definition
    include Comparable

    attr_reader :name, :version

    def initialize(name, version)
      @name = name
      @version = version.to_i
    end

    def to_sql
      File.read(path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def path
      Scenic.configuration.definitions_path.join(filename)
    end

    def <=>(other)
      version <=> other.version
    end

    private

    def filename
      "#{name.to_s.tr('.', '_')}_v#{version.to_s.rjust(2, '0')}.sql"
    end
  end
end
