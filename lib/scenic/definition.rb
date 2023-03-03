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
      Rails.root.join(path)
    end

    def path
      default_view_path = File.join('db', 'views')
      view_filename = filename
      view_paths = Array(ActiveRecord::Base.connection_config[:scenic_views_paths])
      view_paths = [default_view_path] if view_paths.empty?

      full_view_path = nil
      view_paths.each do |path|
        full_view_path = File.join(path, view_filename)
        break if File.exist?(full_view_path)
      end
      full_view_path
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
