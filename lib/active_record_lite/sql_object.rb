require "active_support/inflector"
require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'


class SQLObject < MassObject
  extend Searchable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    unless @table_name
      self.class.underscore.pluralize
    end

    @table_name
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")

    map_results(results)
  end

  def self.find(id)
    results = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", id)

    map_results(results).first
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end


  private

    def self.map_results(results)
      results.map do |params|
        self.new(params)
      end
    end

    def create
      query = <<-SQL
        INSERT INTO
          #{self.class.table_name} (#{attribute_strings.join(", ")})
        VALUES
          (#{attribute_strings.map { "?" }.join(", ")})
      SQL

      DBConnection.execute(query, attribute_values)

      self.id = DBConnection.last_insert_row_id
      self
    end

    def update
      query = <<-SQL
        UPDATE
          #{self.class.table_name}
        SET
          #{attribute_strings.map { |attribute| "#{attribute} = ?" }.join(", ")}
        WHERE
          id = #{self.id}
      SQL

      DBConnection.execute(query, attribute_values)

      self
    end

    def attributes
      all = instance_variables
      all.delete(:@id)

      all
    end

    def attribute_strings
      attributes.map { |attribute| attribute.to_s[1..-1] }
    end

    def attribute_values
      attributes.map do |attribute|
        instance_variable_get(attribute)
      end
    end
end
