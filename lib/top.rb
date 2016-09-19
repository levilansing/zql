module ZQL
  class Top
    include Token
    prepend Function

    def initialize(value)
      @value = ZQL.use value
      if value.respond_to?(:unwind!)
        @tail = value.unwind!
        @tail.shift
      end

    end

    def to_sql
      "top #{@value.to_sql}"
    end
  end
end
