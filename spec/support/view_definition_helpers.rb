module ViewDefinitionHelpers
  def with_view_definition(name, version, schema)
    definition = Scenic::Definition.new(name, version)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.open(definition.full_path, "w") { |f| f.write(schema) }
    yield
  ensure
    FileUtils.rm_f(definition.full_path)
  end
end
