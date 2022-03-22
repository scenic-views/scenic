module Scenic
  # @api private
  class Definition
    def initialize(name, version)
      @name = name.to_s
      @version = version.to_i
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      (Rails.root || Pathname.new(Dir.pwd)).join(path)
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
