module DatabaseSchemaHelpers
  def dump_schema(stream)
    case ActiveRecord.gem_version
    when Gem::Requirement.new(">= 7.2")
      ActiveRecord::SchemaDumper.dump(Search.connection_pool, stream)
    else
      ActiveRecord::SchemaDumper.dump(Search.connection, stream)
    end
  end

  def ar_connection
    ActiveRecord::Base.connection
  end

  def create_materialized_view(name, sql)
    ar_connection.execute("CREATE MATERIALIZED VIEW #{name} AS #{sql}")
  end

  def add_index(view, columns, name: nil)
    ar_connection.add_index(view, columns, name: name)
  end

  def column_default(view_name, column_name)
    ar_connection.select_value(<<~SQL)
      SELECT pg_get_expr(d.adbin, d.adrelid)
      FROM pg_attrdef d
        JOIN pg_class c ON c.oid = d.adrelid
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = d.adnum
      WHERE c.relname = '#{view_name}' AND a.attname = '#{column_name}'
    SQL
  end

  def indexes_for(view_name)
    Scenic::Adapters::Postgres::Indexes
      .new(connection: ar_connection)
      .on(view_name)
  end
end
