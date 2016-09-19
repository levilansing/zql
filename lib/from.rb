module ZQL
  class From
    prepend Function

    def initialize(*args)
      ZQL.use(args)
      @tail = args
      @sources = unwind!
      @sources.shift
    end

    def to_sql
      "from #{ZQL.join(@sources)}"
    end
  end
end
