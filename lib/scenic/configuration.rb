module Scenic
  class Configuration
    # The Scenic database adapter instance to use when executing SQL.
    # Defualts to [Scenic::Adapters::Postgres.new]
    # @return Scenic adapter
    attr_accessor :database

    def initialize
      @database = Scenic::Adapters::Postgres.new
    end
  end

  # @return [Scenic::Configuration] Scenic's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set Scenic's configuration
  # @param config [Scenic::Configuration]
  def self.configuration=(config)
    @configuration = config
  end

  # Modify Scenic's current configuration
  # @yieldparam [Scenic::Configuration] config current Scenic config
  # ```
  # Scenic.configure do |config|
  #   config.database = Scenic::Adapters::Postgres
  # end
  # ```
  def self.configure
    yield configuration
  end
end
