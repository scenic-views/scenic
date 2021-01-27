require_relative "definition"

module Scenic
  # @api private
  class Definitions
    include Enumerable

    attr_reader :name, :views_directory_path

    def initialize(name)
      @name = name
    end

    def each
      versions.each do |version|
        yield Scenic::Definition.new(name, version)
      end
    end

    def versions
      @versions ||= Dir.entries(Scenic.configuration.definitions_path)
        .map { |filename| /\A#{name}_v(?<version>\d+)\.sql\z/.match(filename) }
        .compact
        .map { |match| match["version"].to_i }
        .sort
    end

    private

    def version_regex
      /\A#{name}_v(?<version>\d+)\.sql\z/
    end
  end
end
