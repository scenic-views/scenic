module Scenic
  # @api private
  class Definition
    def initialize(name, version, type=:view)
      @name = name
      @version = version.to_i
      @type = type.to_s
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define #{@type.pluralize} query in #{path} before migrating."
        end
      end
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      File.join("db", @type.pluralize, filename)
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    def filename
      "#{@name}_v#{version}.sql"
    end
  end
end
