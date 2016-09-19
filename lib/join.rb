module ZQL
  class Join
    prepend Function

    def initialize(*args)
      @tail = args
      @tail = unwind!
      @tail.shift     # remove self
      @destination = ZQL.use(@tail.shift)
      apply_tail!(@tail)
      if @destination.nil? || @tail.length > 1
        puts 'poo'
        raise GrammarException, 'join requires exactly one argument'
      end
      @join_type = nil
    end

    def as(*_args)
      raise GrammarException, 'keyword join is not aliasable'
    end

    def type=(join_type)
      @join_type = join_type
    end

    # @param [Condition|Expression] predicate
    def on(predicate)
      @predicate = ZQL.use predicate
      self
    end

    def to_sql
      sql = "#{@join_type ? "#{@join_type} " : ''}join #{@destination.to_sql}"
      sql += " on #{@predicate.to_sql}" if @predicate
      sql
    end
  end
end
