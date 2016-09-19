module ZQL
  class Where
    prepend Function
    def initialize(*args)
      ZQL.use(args[0])
      @predicate = args[0]
    end

    def to_sql
      "where #{@predicate.to_sql}"
    end
  end
end
