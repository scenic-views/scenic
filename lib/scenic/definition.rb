module Scenic
  # @api private
  class Definition
    def initialize(name, version, custom_path)
      @name = name
      @version = version.to_i
      @custom_path = custom_path
    end

    def to_sql
      File.read(full_path).tap do |content|
        if content.empty?
          raise "Define view query in #{path} before migrating."
        end
      end
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      if @custom_path.blank?
        File.join('db', 'views', filename)
      else
        File.join(@custom_path, 'views', filename)
      end
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
