require_relative "adapters/postgres"

module Scenic
  class Configuration
    # The Scenic database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Adapters::Postgres}
    # @return Scenic adapter
    attr_accessor :database

    # The full path for files containing SQL definitions.
    #
    # Defaults to `Rails.root.join("db", "views")` an instance of {Pathname}
    # @return the path
    attr_accessor :definitions_path

    def initialize
      self.database = Scenic::Adapters::Postgres.new
      self.definitions_path = Rails.root.join("db", "views")
    end
  end

  # @return [Scenic::Configuration] Scenic's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set Scenic's configuration
  #
  # @param config [Scenic::Configuration]
  def self.configuration=(config)
    @configuration = config
  end

  # Modify Scenic's current configuration
  #
  # @yieldparam [Scenic::Configuration] config current Scenic config
  # ```
  # Scenic.configure do |config|
  #   config.database = Scenic::Adapters::Postgres.new
  # end
  # ```
  def self.configure
    yield configuration
  end
end
