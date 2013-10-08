require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :name, :class_name, :primary_key, :foreign_key

  def other_class
    class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name        = name
    @class_name  = get_class_name(name, params)
    @primary_key = get_primary_key(name, params)
    @foreign_key = get_foreign_key(name, params)
  end

  def type
  end

  private
    def get_class_name(name, params)
      return params[:class_name].to_s if params[:class_name]

      name.to_s.camelize
    end

    def get_primary_key(name, params)
      return params[:primary_key].to_s if params[:primary_key]

      "id"
    end

    def get_foreign_key(name, params)
      return params[:foreign_key].to_s if params[:foreign_key]

      "#{name}_id"
    end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @name = name
    @class_name  = get_class_name(name, params)
    @primary_key = get_primary_key(name, params)
    @foreign_key = get_foreign_key(name, params, self_class)
  end

  def type
  end


  private

    def get_class_name(name, params)
      return params[:class_name].to_s if params[:class_name]

      name.to_s.singularize.camelize
    end

    def get_primary_key(name, params)
      return params[:primary_key].to_s if params[:primary_key]

      "id"
    end

    def get_foreign_key(name, params, self_class)
      return params[:foreign_key].to_s if params[:foreign_key]

      "#{self_class.to_s.underscore}_id"
    end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    assoc_params[name] = assoc

    define_method(name) do |reload = false|
      if !reload && self.instance_variable_get("@#{assoc.name}")
        return self.instance_variable_get("@#{assoc.name}")
      end

      primary_key_val = self.instance_variable_get("@#{assoc.foreign_key}")
      results = DBConnection.execute(<<-SQL, primary_key_val)
        SELECT
          *
        FROM
          #{assoc.other_table}
        WHERE
          #{assoc.primary_key} = ?
      SQL
      assoc.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, self.class.to_s)
    assoc_params[name] = assoc

    define_method(name) do |reload = false|
      if !reload && self.instance_variable_get("@#{assoc.name}")
        return self.instance_variable_get("@#{assoc.name}")
      end

      foreign_key_val = self.instance_variable_get("@#{assoc.primary_key}")
      results = DBConnection.execute(<<-SQL, foreign_key_val)
        SELECT
          *
        FROM
          #{assoc.other_table}
        WHERE
          #{assoc.foreign_key} = ?
      SQL

      assoc.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    assoc1 = assoc_params[assoc1]

    define_method(name) do |reload = false|
      if !reload && self.instance_variable_get("@#{assoc1.name}")
        return self.instance_variable_get("@#{assoc1.name}")
      end

      assoc2 = assoc1.other_class.assoc_params[assoc2]

      foreign_key_val = self.instance_variable_get("@#{assoc1.foreign_key}")
      results = DBConnection.execute(<<-SQL, foreign_key_val)
        SELECT
          #{assoc2.other_table}.*
        FROM
          #{assoc2.other_table}
        INNER JOIN
          #{assoc1.other_table}
          ON (#{assoc2.other_table}.#{assoc2.primary_key} = #{assoc1.other_table}.#{assoc2.foreign_key})
        WHERE
          #{assoc1.other_table}.#{assoc1.primary_key} = ?
      SQL

      assoc2.other_class.parse_all(results).first
    end
  end
end
