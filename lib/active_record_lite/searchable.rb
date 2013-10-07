require_relative './db_connection'

module Searchable
  def where(params)
    query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{params.keys.map { |param| "#{param} = ?" }.join(" AND ")}
    SQL

    results = DBConnection.execute(query, *params.values)

    map_results(results)
  end
end
