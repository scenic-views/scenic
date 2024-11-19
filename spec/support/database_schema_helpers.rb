module DatabaseSchemaHelpers
  def dump_schema(stream)
    case ActiveRecord.gem_version
    when Gem::Requirement.new(">= 7.2")
      ActiveRecord::SchemaDumper.dump(Search.connection_pool, stream)
    else
      ActiveRecord::SchemaDumper.dump(Search.connection, stream)
    end
  end
end
