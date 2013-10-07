class Relation
  include Enumerable

  attr_reader :klass

  def initialize(klass)
    @klass = klass
  end

  def where(params)
    wheres << params

    self
  end

  def result
    @result ||= run
  end

  def to_s
    self.result.to_s
  end

  def inspect
    self.result.inspect
  end

  def method_missing(name, *args, &block)
    self.result.send(name, *args, &block)
  end


  private

    def wheres
      @wheres ||= []
    end

    def make_where_clause
      wheres.map do |where|
        where.map { |k, v| "#{k} = ?" }.join(" AND ")
      end.join(" AND ")
    end

    def make_where_values
      values = []
      wheres.each do |where|
        where.each { |k, v| values << v }
      end

      values
    end

    def run
      results = DBConnection.execute(<<-SQL, *make_where_values)
        SELECT
          *
        FROM
          #{klass.table_name}
        WHERE
          #{make_where_clause}
      SQL

      klass.parse_all(results)
    end
end
