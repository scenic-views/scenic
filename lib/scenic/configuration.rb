module Scenic
  class Configuration
    # Collection of database adapters for multi-database support.
    # Access specific databases using database names as keys.
    #
    # @example
    #   Scenic.configure do |config|
    #     config.databases[:secondary] = Scenic::Adapters::Postgres.new(SecondaryRecord)
    #   end
    #
    # @return [ActiveSupport::OrderedOptions] hash of database adapters
    attr_reader :databases

    # The Scenic database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Adapters::Postgres}
    # @return Scenic adapter
    def database
      @databases[:default]
    end

    def database=(adapter)
      @databases[:default] = adapter
    end

    def initialize
      @databases = ActiveSupport::OrderedOptions.new
      @databases[:default] = Scenic::Adapters::Postgres.new
    end

    # Returns the database adapter for the specified database name.
    #
    # @param name [Symbol] the database name (defaults to :default)
    # @return [Scenic::Adapters::Postgres] the database adapter
    def database_adapter(name = :default)
      @databases[name] || @databases[:default]
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
