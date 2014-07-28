module ViewDefinitionHelpers
  def with_view_definition(name, version, schema)
    view_file = ::Rails.root.join("db", "views", "#{name}_v#{version}.sql")
    File.open(view_file, "w") { |f| f.write(schema) }
    yield
  ensure
    File.delete view_file
  end
end
