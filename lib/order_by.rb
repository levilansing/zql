module ZQL
  class OrderBy
    prepend Function

    def initialize(*args)
      @tail = ZQL.use(args)
      @args = unwind!
      @args.shift
      @args.delete_if { |arg| arg.is_a?(Comma) }
      @args_managed = true
    end

    def to_sql
      args = []
      @args.each_with_index do |param|
        sql_str = ZQL.encapsulate(param)
        if args.length > 0 && sql_str.match(/\A(?:(?:asc|desc|nulls|first|last)(?:\z| ))+\z/)
          sql_str = "#{args.pop} #{sql_str}"
        end
        args << sql_str
      end

      args = args.map do |param|
        ZQL.encapsulate(param)
      end.join(', ')

      "order by #{args}"
    end
  end
end
