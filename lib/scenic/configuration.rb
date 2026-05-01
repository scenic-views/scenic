module Scenic
  # Raised when a Scenic operation requests a database that hasn't been
  # registered with `Scenic.configure`.
  class UnknownDatabaseError < ArgumentError; end

  class Configuration
    # Collection of database adapters for multi-database support.
    # Access specific databases using database names as keys.
    #
    # @example
    #   Scenic.configure do |config|
    #     config.databases[:secondary] = Scenic::Adapters::Postgres.new(SecondaryRecord)
    #   end
    #
    # @return [Hash] hash of database adapters keyed by symbol
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
      @databases = {}
      @databases[:default] = Scenic::Adapters::Postgres.new
    end

    # Returns the database adapter for the specified database name.
    #
    # Raises {Scenic::UnknownDatabaseError} when the requested name
    # has not been registered with {Scenic.configure}. The :default
    # adapter is always available.
    #
    # @param name [Symbol] the database name (defaults to :default)
    # @return [Scenic::Adapters::Postgres] the database adapter
    def database_adapter(name = :default)
      @databases.fetch(name) do
        raise UnknownDatabaseError,
          ":#{name} is not a configured Scenic database. " \
          "Configured databases: #{@databases.keys.inspect}. " \
          "If this raised during application boot, an initializer or " \
          "rake task is calling Scenic.database(:#{name}) before " \
          "Scenic.configure has registered it."
      end
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
