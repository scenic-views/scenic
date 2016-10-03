module Scenic
  class Configuration
    # The Scenic database adapter instance to use when executing SQL.
    #
    # Defualts to an instance of {Adapters::Postgres}
    # @return Scenic adapter
    attr_accessor :database

    # A flag indicating if functions should be dumped with their schema namespace
    #
    # Defualts to false
    # @return boolean
    attr_accessor :dump_function_namespace_in_schema

    def initialize
      @database = Scenic::Adapters::Postgres.new
      @dump_function_namespace_in_schema = false
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
