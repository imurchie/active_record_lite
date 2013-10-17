require_relative 'db_connection'
require_relative "relation"

module ActiveRecordLite
  module Searchable
    def where(params)
      Relation.new(self).where(params)
    end

    # def where(params)
    #   query = <<-SQL
    #     SELECT
    #       *
    #     FROM
    #       #{table_name}
    #     WHERE
    #       #{params.keys.map { |param| "#{param} = ?" }.join(" AND ")}
    #   SQL

    #   results = DBConnection.execute(query, *params.values)

    #   parse_all(results)
    # end
  end
end
