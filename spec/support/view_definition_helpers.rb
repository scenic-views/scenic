module ViewDefinitionHelpers
  def with_view_definition(name, version, schema)
    definition = Scenic::Definition.new(name, version)
    FileUtils.mkdir_p(File.dirname(definition.path))
    File.open(definition.path, "w") { |f| f.write(schema) }
    yield
  ensure
    FileUtils.rm_f(definition.path)
  end
end
