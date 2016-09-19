module ZQL
  class WithClause
    def initialize(*statements)
      @statements = ZQL.use statements
    end

    def to_sql
      clauses = @statements.map do |statement|
        name = statement.instance_variable_get(:@alias_name)
        raise GrammarException, 'with clauses must have an alias' if name.nil?
        statement.instance_variable_set(:@alias_name, nil)
        sql = statement.to_sql
        statement.instance_variable_set(:@alias_name, name)
        "#{name} as #{sql}"
      end
      'with ' + clauses.join(', ')
    end
  end
end
