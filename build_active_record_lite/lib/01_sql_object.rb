require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns[0].map { |column| column.to_sym }
  end

  #Columns are all symbols
  def self.finalize!
    self.columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column.to_s}=") do |val| 
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.downcase.pluralize
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    self.parse_all(query)
  end

  def self.parse_all(results)
    parsed = []
    results.each do |result|
      instance = self.new
      result.each do |k,v|
        instance.send("#{k}=", v)
      end
      parsed << instance
    end
    parsed
  end

  def self.find(id)
    found = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    self.parse_all(found).first
  end

  def initialize(params = {})

  end

  def attributes

  end

  def attribute_values

  end

  def insert

  end

  def update

  end

  def save

  end
end
