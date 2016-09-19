module ZQL
  class Executor; end

  class Encapsulation
    include Token
    prepend Aliasable

    def initialize(inner)
      @inner = inner
    end

    def to_sql
      sql = if @inner.is_a? Executor
        @inner.compile
      else
        @inner.to_sql
      end

      if sql.include?("\n")
        # TODO: get list of lines out of executor to make this safe
        "(\n  #{sql.gsub("\n", "\n  ")}\n)"
      else
        "(#{sql})"
      end
    end
  end
end
