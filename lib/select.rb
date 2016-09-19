module ZQL
  class Select
    prepend Function

    def initialize(*args)
      ZQL.use(args)
      @tail = args
      @tail = unwind!
      @tail.shift
      @what = unwind!
      @what.shift
      if @what.first.is_a?(Top)
        @top = @what.shift
      end
    end

    def to_sql
      args = ZQL.join(@what)

      ['select', @top&.to_sql, args].compact.join(' ')
    end
  end
end
