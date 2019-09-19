require_relative 'db_connection'
require 'active_support/inflector'

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
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    keys = attributes.keys
    q_mark_arr = ['?'] * attribute_values.length
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{keys.join(',')})
      VALUES
        (#{q_mark_arr.join(',')})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    keys = attributes.keys
    q_mark_arr = ['?'] * attribute_values.length
    set_mapping = self.class.columns.map { |column| "#{column} = ?"}
    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_mapping.join(',')}
      WHERE
        id = #{self.id}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def save
    self.id.nil? ? insert : update
  end
end
