module Scenic
  class View
    attr_reader :name, :definition
    delegate :<=>, to: :name

    def initialize(view_row)
      @name = view_row["viewname"]
      @definition = view_row["definition"].strip
    end

    def ==(other)
      name == other.name &&
        definition == other.definition
    end

    def to_schema
      <<-DEFINITION.strip_heredoc
        create_view :#{name}, sql_definition:<<-\SQL
          #{definition}
        SQL
        
      DEFINITION
    end
  end
end
