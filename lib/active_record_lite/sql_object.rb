require "active_support/inflector"
require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require_relative "./relation"


class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    unless @table_name
      @table_name = self.to_s.underscore.pluralize
    end

    @table_name
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")

    parse_all(results)
  end

  def self.find(id)
    results = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", id)

    parse_all(results).first
  end

  def includes(*args)
    Relation.new.includes(*args)
  end

  def save
    save!
  rescue
    false
  end

  def save!
    if self.id.nil?
      create!
    else
      update!
    end
  end

  def method_missing(name, *args, &block)
    possible_attr = name.to_s.sub( /=$/, "")
    if self.class.schema.keys.include?(possible_attr)
      if name =~ /=/
        # setter
        self.class.class_eval do
          define_method(name) do |value|
            instance_variable_set("@#{possible_attr}", value)
          end
        end
        self.send(name, *args)  # need to call the newly minted method
      else
        # getter
        self.class.class_eval do
          define_method(name) do
            instance_variable_get("@#{possible_attr}")
          end
        end
        self.send(name)  # need to call the newly minted method
      end
    else
      super
    end
  end

  def respond_to?(symbol)
    possible_attr = name.to_s.sub( /=$/, "")
    if self.class.schema.keys.include?(possible_attr)
      true
    else
      super
    end
  end


  private

    # access the db schema in order to build the object correctly
    def self.schema
      unless @schema
        @schema = {}
        DBConnection.table_info(self.table_name) do |row|
          @schema[row["name"]] = row["type"]
        end
      end

      @schema
    end

    def create!
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

    def update!
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
      all = schema.keys
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
