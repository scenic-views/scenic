module Scenic
  # @api private
  #
  # Resolves filesystem paths and Rails-config names for a given Scenic
  # database identifier. Single source of truth for "where do view SQL
  # files and migrations live for this database?" — every consumer
  # (Definition, view generator, schema dumper) routes through here.
  #
  # Contract: Scenic symbols (:default, :secondary, ...) in, Rails
  # config names ("primary", "secondary", ...) out.
  module DatabasePaths
    DEFAULT = :default

    def self.config_name(database)
      return "primary" if default?(database)
      database.to_s
    end

    def self.database_for_config_name(config_name)
      return DEFAULT if config_name.nil? || config_name == "primary"
      config_name.to_sym
    end

    def self.views_path(database)
      if default?(database)
        Rails.root.join("db/views")
      else
        Rails.root.join(configured_views_path(database) || "db/#{database}_views")
      end
    end

    def self.migrations_path(database)
      if default?(database)
        "db/migrate"
      else
        configured_migrations_path(database) || "db/#{database}_migrate"
      end
    end

    def self.default?(database)
      database.nil? || database == DEFAULT
    end

    def self.configured_views_path(database)
      Array(db_config(database)&.configuration_hash&.dig(:views_paths)).first
    end

    def self.configured_migrations_path(database)
      Array(db_config(database)&.migrations_paths).first
    end

    def self.db_config(database)
      ActiveRecord::Base.configurations.configs_for(
        env_name: Rails.env,
        name: config_name(database)
      )
    end
  end
end
