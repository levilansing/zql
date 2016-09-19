module ZQL
  class Reference
    include Token
    prepend Aliasable
    prepend Algebraic
    include Expressable

    def initialize(name)
      @name = name.to_s
    end

    # @note only called from Algebraic if there are no params
    def *(*_other)
      ZQL.use(self)
      ZQL.add Reference.new("#{@name}.*")
    end

    def to_s
      @name
    end
    alias :to_str :to_s

    def to_sql
      @name.to_s
    end

    def method_missing(name, *args)
      return super if ZQL.compiling?

      ZQL.use(self)
      if args.length > 0
        ZQL.add Template.make_generic_function("#{@name}.#{name}", *args)
      else
        ZQL.add Reference.new("#{@name}.#{name}")
      end
    end
  end
end
