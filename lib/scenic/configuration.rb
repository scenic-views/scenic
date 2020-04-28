module Scenic
  class Configuration
    # Set the default path to store the views.
    #
    # Defaults to db/views on Rails root
    DEFAULT_VIEWS_PATH = "db/views".freeze

    # The Scenic database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Adapters::Postgres}
    # @return Scenic adapter
    attr_accessor :database

    # The Scenic database adapter instance to use when executing SQL.
    # The path where the views SQL files are stored
    #
    # Defaults to 'db/views'
    # @return string
    attr_accessor :views_path

    def initialize
      @database = Scenic::Adapters::Postgres.new
      @views_path = DEFAULT_VIEWS_PATH
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
