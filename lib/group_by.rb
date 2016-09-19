module ZQL
  class GroupBy
    prepend Function

    def initialize(*args)
      @tail = ZQL.use(args)
      @args = unwind!
      @args.shift
      @uses_commas = true
    end

    def to_sql
      'group by'
    end
  end
end
