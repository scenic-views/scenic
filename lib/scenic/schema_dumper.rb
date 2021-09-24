require "rails"

module Scenic
  # @api private
  module SchemaDumper
    # A hash to do topological sort
    class TSortableHash < Hash
      include TSort

      alias tsort_each_node each_key
      def tsort_each_child(node, &block)
        fetch(node).each(&block)
      end
    end

    # Query for the dependencies between views
    DEPENDENT_SQL = <<~SQL.freeze
      SELECT distinct dependent_ns.nspname AS dependent_schema
      , dependent_view.relname AS dependent_view
      , source_ns.nspname AS source_schema
      , source_table.relname AS source_table
      FROM pg_depend
      JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
      JOIN pg_class as dependent_view ON pg_rewrite.ev_class = dependent_view.oid
      JOIN pg_class as source_table ON pg_depend.refobjid = source_table.oid
      JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
      JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
      WHERE dependent_ns.nspname = ANY (current_schemas(false)) AND source_ns.nspname = ANY (current_schemas(false))
      AND source_table.relname != dependent_view.relname
      AND source_table.relkind IN ('m', 'v') AND dependent_view.relkind IN ('m', 'v')
      ORDER BY dependent_view.relname;
    SQL

    def tables(stream)
      super
      views(stream)
    end

    def views(stream)
      if dumpable_views_in_database.any?
        stream.puts
      end

      dumpable_views_in_database.each do |view|
        stream.puts(view.to_schema)
        indexes(view.name, stream)
      end
    end

    private

    def dumpable_views_in_database
      if @ordered_dumpable_views_in_database
        return @ordered_dumpable_views_in_database
      end

      existing_views = Scenic.database.views.reject do |view|
        ignored?(view.name)
      end

      @ordered_dumpable_views_in_database =
        tsorted_views(existing_views.map(&:name)).map do |view_name|
          existing_views.find { |ev| ev.name == view_name }
        end.compact
    end

    # When dumping the views, their order must be topologically
    # sorted to take into account dependencies
    def tsorted_views(views_names)
      views_hash = TSortableHash.new

      ::Scenic.database.execute(DEPENDENT_SQL).each do |relation|
        source_v = relation["source_table"]
        dependent = relation["dependent_view"]
        views_hash[dependent] ||= []
        views_hash[source_v] ||= []
        views_hash[dependent] << source_v
        views_names.delete(source_v)
        views_names.delete(dependent)
      end

      # after dependencies, there might be some views left
      # that don't have any dependencies
      views_names.sort.each { |v| views_hash[v] = [] }

      views_hash.tsort
    end

    unless ActiveRecord::SchemaDumper.private_instance_methods(false).include?(:ignored?)
      # This method will be present in Rails 4.2.0 and can be removed then.
      def ignored?(table_name)
        ["schema_migrations", ignore_tables].flatten.any? do |ignored|
          case ignored
          when String then remove_prefix_and_suffix(table_name) == ignored
          when Regexp then remove_prefix_and_suffix(table_name) =~ ignored
          else
            raise StandardError, "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values."
          end
        end
      end
    end
  end
end
