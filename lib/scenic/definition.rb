module Scenic
  # @api private
  class Definition
    def initialize(name, version, database: nil, views_path: nil)
      @name = name.to_s
      @version = version.to_i
      @database = database
      @views_path = views_path
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      views_path.join(filename)
    end

    def path
      full_path.relative_path_from(Rails.root).to_s
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    attr_reader :name

    def views_path
      @views_path ||= Scenic::DatabasePaths.views_path(@database)
    end

    def filename
      "#{UnaffixedName.for(name).tr(".", "_")}_v#{version}.sql"
    end
  end
end
