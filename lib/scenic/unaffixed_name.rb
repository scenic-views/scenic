module Scenic
  # The name of a view or table according to rails.
  #
  # This removes any table name prefix or suffix that is configured via
  # ActiveRecord. This allows, for example, the SchemaDumper to dump a view with
  # its unaffixed name, consistent with how rails handles table dumping.
  class UnaffixedName
    # Gets the unaffixed name for the provided string
    # @return [String]
    #
    # @param name [String] The (potentially) affixed view name
    def self.for(name)
      new(name, config: ActiveRecord::Base).call
    end

    def initialize(name, config:)
      @name = name
      @config = config
    end

    def call
      prefix = Regexp.escape(config.table_name_prefix)
      suffix = Regexp.escape(config.table_name_suffix)
      name.sub(/\A#{prefix}(.+)#{suffix}\z/, "\\1")
    end

    private

    attr_reader :name, :config
  end
end
