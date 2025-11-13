class FakeAdapter
  attr_reader :name, :calls

  def initialize(name)
    @name = name
    @calls = []
  end

  def views
    record_call(__method__)
    []
  end

  def create_view(name, sql_definition)
    record_call(__method__, name: name, sql_definition: sql_definition)
  end

  def update_view(name, sql_definition)
    record_call(__method__, name: name, sql_definition: sql_definition)
  end

  def replace_view(name, sql_definition)
    record_call(__method__, name: name, sql_definition: sql_definition)
  end

  def drop_view(name)
    record_call(__method__, name: name)
  end

  def create_materialized_view(name, sql_definition, no_data: false)
    record_call(__method__, name: name, sql_definition: sql_definition, no_data: no_data)
  end

  def update_materialized_view(name, sql_definition, no_data: false, side_by_side: false)
    record_call(__method__, name: name, sql_definition: sql_definition, no_data: no_data, side_by_side: side_by_side)
  end

  def drop_materialized_view(name)
    record_call(__method__, name: name)
  end

  def refresh_materialized_view(name, concurrently: false, cascade: false)
    record_call(__method__, name: name, concurrently: concurrently, cascade: cascade)
  end

  def populated?(name)
    record_call(__method__, name: name)
    true
  end

  def connection
    self
  end

  def called?(method_name)
    @calls.any? { |call| call[:method] == method_name }
  end

  def call_count(method_name)
    @calls.count { |call| call[:method] == method_name }
  end

  private

  def record_call(method_name, **args)
    @calls << {method: method_name, args: args, adapter: @name}
  end
end
