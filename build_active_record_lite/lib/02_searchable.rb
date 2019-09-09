require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    param_mapping = params.keys.map { |key| "#{key} = ?" }
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{param_mapping.join(' AND ')}
    SQL
    self.parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
