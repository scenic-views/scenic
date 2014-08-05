module ViewDefinitionHelpers
  def with_view_definition(name, version, schema)
    definition = Scenic::Definition.new(name, version)
    File.open(definition.full_path, "w") { |f| f.write(schema) }
    yield
  ensure
    File.delete definition.full_path
  end
end
