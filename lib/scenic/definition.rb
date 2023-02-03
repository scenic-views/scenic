module Scenic
  # @api private
  class Definition
    def initialize(name, version, root_path: Rails.root)
      @name = name.to_s
      @version = version.to_i
      @root_path = root_path.is_a?(String) ? Pathname.new(root_path) : root_path
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      @root_path.join(path)
    end

    def path
      File.join("db", "views", filename)
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    attr_reader :name

    def filename
      "#{UnaffixedName.for(name).tr('.', '_')}_v#{version}.sql"
    end
  end
end
