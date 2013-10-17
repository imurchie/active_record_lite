require "associatable"

module ActiveRecordLite
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

    def includes(*args)
      included_assocs.push(*args)
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

      def included_assocs
        @included ||= []
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

        objs = klass.parse_all(results)
        run_included_assocs!(objs)

        objs
      end

      def run_included_assocs!(objs)
        included_assocs.each do |assoc_name|
          assoc = klass.assoc_params[assoc_name]

          if assoc.is_a?(HasManyAssocParams)
            run_included_has_many_assoc!(assoc, objs)
          elsif assoc.is_a?(BelongsToAssocParams)
            run_included_belongs_to_assoc!(assoc, objs)
          elsif assoc.is_a?(Array)
            run_included_has_one_through_assoc!(assoc_name, assoc, objs)
          end
        end

        objs
      end

      def run_included_has_many_assoc!(assoc, objs)
        keys = objs.map do |obj|
          obj.instance_variable_get("@#{assoc.primary_key}")
        end

        query = <<-SQL
          SELECT
            *
          FROM
            #{assoc.other_table}
          WHERE
            #{assoc.other_table}.#{assoc.foreign_key} IN (#{keys.map{ "?" }.join(", ")})
        SQL

        results = DBConnection.execute(query, *keys)
        map_has_many_assoc(results, objs, assoc)
      end

      def run_included_belongs_to_assoc!(assoc, objs)
        keys = objs.map do |obj|
          obj.instance_variable_get("@#{assoc.foreign_key}")
        end

        results = DBConnection.execute(<<-SQL, *keys)
          SELECT
            *
          FROM
            #{assoc.other_table}
          WHERE
            #{assoc.other_table}.#{assoc.primary_key} IN (#{keys.map { "?" }.join(", ")})
        SQL

        map_belongs_to_assoc(results, objs, assoc)
      end

      def run_included_has_one_through_assoc!(name, assoc, objs)
        assoc1 = klass.assoc_params[assoc[0]]
        assoc2 = assoc1.other_class.assoc_params[assoc[1]]

        keys = objs.map do |obj|
          obj.instance_variable_get("@#{assoc1.foreign_key}")
        end

        results = DBConnection.execute(<<-SQL, keys)
          SELECT
            #{assoc2.other_table}.*, #{assoc1.other_table}.#{assoc1.primary_key}
          FROM
            #{assoc2.other_table}
          INNER JOIN
            #{assoc1.other_table}
            ON (#{assoc2.other_table}.#{assoc2.primary_key} = #{assoc1.other_table}.#{assoc2.foreign_key})
          WHERE
            #{assoc1.other_table}.#{assoc1.primary_key} IN (#{keys.map { "?" }.join(", ")})
        SQL
  p assoc
        map_has_one_through_assoc(results, objs, name, assoc1, assoc2)
        # assoc2.other_class.parse_all(results).first
      end

      def map_has_many_assoc(results, objs, assoc)
        assocs = (Hash.new { |h, k| h[k] = [] }).tap do |hash|
          results.each do |params|
            key = params[assoc.foreign_key]
            hash[key] << params
          end
        end

        objs.each do |obj|
          key = obj.instance_variable_get("@#{assoc.primary_key}")
          results = assocs[key]
          obj.instance_variable_set("@#{assoc.name}", assoc.other_class.parse_all(results))
        end

        objs
      end

      def map_belongs_to_assoc(results, objs, assoc)
        assocs = {}.tap do |hash|
          results.each do |params|
            key = params[assoc.primary_key]
            hash[key] = params
          end
        end

        objs.each do |obj|
          key = obj.instance_variable_get("@#{assoc.foreign_key}")
          results = assocs[key]
          obj.instance_variable_set("@#{assoc.name}", assoc.other_class.parse_all([results]))
        end

        objs
      end

      def map_has_one_through_assoc(results, objs, name, assoc1, assoc2)
        assocs = {}.tap do |hash|
          results.each do |params|
            key = params[assoc1.primary_key]
            params.delete(assoc1.primary_key)
            hash[key] = params
          end
        end

        objs.each do |obj|
          key = obj.instance_variable_get("@#{assoc1.foreign_key}")
          results = assocs[key]
          obj.instance_variable_set("@#{name}", assoc2.other_class.parse_all([results]))
        end

        objs
      end
  end
end
