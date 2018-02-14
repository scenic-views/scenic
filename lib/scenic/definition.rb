module Scenic
  # @api private
  class Definition
    def initialize(name, version)
      @name = name
      @version = version.to_i
    end

    def to_sql
      File.read(find_definition).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def find_definition
      definition = views_paths.flat_map do |directory|
        Dir.glob("#{directory}/**/#{filename}")
      end.first

      unless definition
        raise "Unable to locate #{filename} in #{views_paths}"
      end

      definition
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      File.join("db", "views", filename)
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    def views_paths
      Rails.application.config.paths["db/views"].expanded
    end

    def filename
      "#{@name}_v#{version}.sql"
    end
  end
end
