module ViewDefinitionHelpers
  def with_view_definition(name, version, schema)
    definition = Scenic::Definition.new(name, version)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.write(definition.full_path, schema)
    yield
  ensure
    FileUtils.rm_f(definition.full_path)
  end
end
