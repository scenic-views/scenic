module DefinitionHelpers

  def with_view_definition(name, version, schema, &block)
    with_definition(name, version, schema, :view, &block)
  end

  def with_function_definition(name, version, schema, &block)
    with_definition(name, version, schema, :function, &block)
  end

  private

  def with_definition(name, version, schema, type)
    definition = Scenic::Definition.new(name, version, type)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.open(definition.full_path, "w") { |f| f.write(schema) }
    yield
  ensure
    FileUtils.rm_f(definition.full_path)
  end
end
