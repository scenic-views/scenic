module Scenic
  module Adapters
    class Postgres
      class UpdateWithCascade
        def initialize(adapter:, name:, definition:, no_data: false, side_by_side: false, speaker: ActiveRecord::Migration.new)
          @adapter = adapter
          @name = name
          @definition = definition
          @no_data = no_data
          @side_by_side = side_by_side
          @speaker = speaker
        end

        def update
          validate_options
          dependent_views = DependentViewsFinder.new(adapter.connection, name).find
          
          return update_base_only if dependent_views.empty?

          adapter.connection.transaction do
            execute_cascade_update(dependent_views)
          end
        end

        private

        attr_reader :adapter, :name, :definition, :no_data, :side_by_side, :speaker

        def validate_options
          if side_by_side && no_data
            raise ArgumentError, "cascade with side_by_side and no_data options is not supported"
          end
        end

        def execute_cascade_update(dependents)
          dependent_state = capture_dependent_state(dependents)
          
          begin
            dependents.reverse_each { |dep| drop_dependent_view(dep) }
            update_base_view
            dependents.each { |dep| recreate_dependent_view(dep, dependent_state[dep]) }
          rescue => e
            raise Postgres::CascadeUpdateFailedError.new(name, e.message)
          end
        end

        def capture_dependent_state(dependents)
          dependents.each_with_object({}) do |view_name, state|
            view_info = find_view_info(view_name)
            unqualified_name = view_name.split('.').last
            indexes = Indexes.new(connection: adapter.connection).on(unqualified_name)
            
            state[view_name] = {
              definition: view_info.definition,
              materialized: view_info.materialized,
              indexes: indexes
            }
          end
        end

        def find_view_info(view_name)
          unqualified_name = view_name.split('.').last
          adapter.views.find { |v| v.name == view_name || v.name == unqualified_name } ||
            raise("View '#{view_name}' not found in adapter.views")
        end

        def drop_dependent_view(view_name)
          view_info = find_view_info(view_name)
          unqualified_name = view_name.split('.').last
          
          if view_info.materialized
            adapter.drop_materialized_view(unqualified_name)
          else
            adapter.drop_view(unqualified_name)
          end
        end

        def update_base_view
          if side_by_side
            SideBySide.new(adapter: adapter, name: name, definition: definition, speaker: speaker).update
          else
            IndexReapplication.new(connection: adapter.connection, speaker: speaker).on(name) do
              adapter.drop_materialized_view(name)
              adapter.create_materialized_view(name, definition, no_data: no_data)
            end
          end
        end

        def recreate_dependent_view(view_name, state)
          unqualified_name = view_name.split('.').last
          view_type = state[:materialized] ? "materialized view" : "view"
          
          speaker.say "   -> Recreating dependent #{view_type} '#{view_name}'"
          
          if state[:materialized]
            adapter.create_materialized_view(unqualified_name, state[:definition])
          else
            adapter.create_view(unqualified_name, state[:definition])
          end
          
          IndexCreation.new(connection: adapter.connection, speaker: speaker)
                      .try_create(state[:indexes])
          
        end

        def update_base_only
          if side_by_side
            SideBySide.new(adapter: adapter, name: name, definition: definition, speaker: speaker).update
          else
            IndexReapplication.new(connection: adapter.connection, speaker: speaker).on(name) do
              adapter.drop_materialized_view(name)
              adapter.create_materialized_view(name, definition, no_data: no_data)
            end
          end
        end

      end
    end
  end
end