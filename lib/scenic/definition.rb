module Scenic
  # @api private
  class Definition
    def initialize(name, version)
      @name = name.to_s
      @version = version
    end

    def to_sql
      ERB.new(File.read(full_path)).result.tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      File.join("db", "views", filename)
    end

    def version
      @version = latest_version if @version == :latest
      @version.to_i.to_s.rjust(2, "0")
    end

    private

    attr_reader :name

    def filename
      "#{UnaffixedName.for(name).tr('.', '_')}_v#{version}.sql"
    end

    def latest_version
      Dir.glob(Rails.root.join('db', 'views', "#{name}*.sql")).sort.last =~ /#{name}_v(\d*).sql/i
      $1
    end
  end
end
