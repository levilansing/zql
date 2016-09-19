module ZQL
  module Function
    include Token
    include Algebraic
    include Expressable

    def to_sql
      return super if @args_managed
      if @args && @args.length > 0
        args = if @uses_commas
          ZQL.join(@args)
        elsif enclosed?
          @args.map { |param| ZQL.encapsulate(param) }.join(', ')
        else
          @args.delete_if { |arg| arg.is_a?(Comma) }
          if @args.length > 1
            @args.map { |param| ZQL.encapsulate(param) }
          elsif @args.length > 0
            @args.map { |param| ZQL.ref(param).to_sql }
          else
            []
          end.join(' ')
        end

        if enclosed?
          "#{super}(#{args})"
        else
          [super, args].join(' ')
        end
      else
        super
      end
    end

    def enclose!
      @enclosed = true
      self
    end

    def enclosed?
      !!@enclosed
    end
  end

  class GenericFunction
    prepend Function
    prepend Aliasable

    def initialize(name, *args)
      @name = ZQL.use name
      @tail = ZQL.use(args)
    end

    def to_s
      @name.to_s
    end

    def to_sql
      "#{@name}"
    end
  end

  class ExplicitFunction
    prepend Function
    prepend Aliasable

    def initialize(name, num_args, *args)
      @name = ZQL.use name
      @tail = ZQL.use(args)
      @args = @tail.shift(num_args)
    end

    def to_s
      @name.to_s
    end

    def to_sql
      @name.to_s
    end
  end
end
