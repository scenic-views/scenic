module RailsConfigurationHelpers
  def with_affixed_tables(prefix: "", suffix: "")
    ActiveRecord::Base.table_name_prefix = prefix
    ActiveRecord::Base.table_name_suffix = suffix
    yield
  ensure
    ActiveRecord::Base.table_name_prefix = ""
    ActiveRecord::Base.table_name_suffix = ""
  end
end
