module ZQL
  class Template
    # hide as many conflicting methods as we can
    # anything we can't hide cannot be used without quoting in sql template
    ALLOWED_METHODS = [
      :proc, :lambda, :to_s, :class, :raise, :catch, :puts, :methods,
      :protected_methods, :public_methods, :singleton_methods, :caller
    ]
    (Kernel.methods - ALLOWED_METHODS).select do |name|
      name =~ /\A[a-z][a-zA-Z_]*\z/
    end.each do |name|
      alias_method "_#{name}", "#{name}" if self.method_defined?(name)
    end.each do |name|
      define_method(name) { |*args| method_missing(name, *args) }
    end

    def select(*what)
      ZQL.add Select.new(*what)
    end

    def from(*args)
      ZQL.add From.new(*args)
    end

    def join(*args)
      when_method(:join, [Object], args) do
        ZQL.add Join.new(*args)
      end
    end

    def where(predicate)
      ZQL.add Where.new(predicate)
    end

    [:count, :min, :max, :avg, :sum].each do |name|
      define_method(name) do |*args|
        when_method(name, [Object], args) { |what| ZQL.add Aggregate.new(name, what) }
      end
    end

    def group_by(*params)
      ZQL.add GenericFunction.new('group by', *params)
    end

    def order_by(*params)
      ZQL.add OrderBy.new(*params)
    end

    def _(&block)
      inner_executor = Executor.new
      ZQL.with_executor(inner_executor, &block)
      ZQL.add Encapsulation.new(inner_executor)
    end

    [:distinct, :all].each do |name|
      define_method(name) do |*args|
        if args.length > 0
          ZQL.add ExplicitFunction.new(name, 1, *args)
        else
          ZQL.add Template.make_generic_function(name, *args)
        end
      end
    end

    def top(*params)
      when_method(:top, [Object], params) do
        ZQL.add Top.new(params[0])
      end
    end

    def with(*statements)
      ZQL.add WithClause.new(*statements)
    end

    def f(*params)
      ZQL.add ExplicitFunction.new(params.shift, params.length, *params).enclose!
    end

    def s(*params)
      when_method(:s, [Object], params) do
        ZQL.add Literal.new("'#{params[0].to_s.gsub("'", "''")}'")
      end
    end

    def l(*params)
      when_method(:l, [Object], params) do
        ZQL.add Literal.new(params.first)
      end
    end

    [:coalesce, :nvl].each do |name|
      define_method(name) do |*args|
        if args.length > 1
          f(name, *args)
        else
          method_missing(name, *args)
        end
      end
    end

    def when_method(name, required, args)
      if required.length == args.length
        ok = true
        required.each_with_index do |types, index|
          types = [types] unless types.is_a?(Array)
          ok &&= types.any? { |type| args[index].kind_of?(type) }
        end
        return yield(*args) if ok
      end
      method_missing(name, *args)
    end

    def respond_to?(name)
      true
    end

    def method_missing(name, *args)
      return super if ZQL.compiling?

      if (matches = name.to_s.match(/\A_(\d+)(?:_(\d+))?_\z/))
        # we are a number (eg: _10_)
        value = matches[1]
        value = "#{value}.#{matches[2]}" if matches[2]
        ZQL.add Template.make_generic_function(value, *args)
      elsif args.length > 0
        ZQL.add Template.make_generic_function(name, *args)
      else
        ZQL.add Reference.new(name)
      end
    end

    def compile
      ZQL.reset_state
      @executors = [executor = Executor.new]
      ZQL.set_current_template(self)
      ZQL.set_current_executor(executor)
      ZQL.add Context::Operation.new(:push, Context.new)
      sql
      @executors.first.compile
    end

    def self.make_generic_function(name, *args)
      if args.length > 0 && args[0].is_a?(GenericFunction) && !args[0].enclosed?
        compound_name = "#{name} #{args[0].to_s}"
        if (fn_class = ZQL::Grammar::MULTI_WORD_FUNCTIONS[compound_name])
          other = ZQL.use args.shift
          other_args = other.unwind!
          other_args.shift
          return fn_class.new(*other_args, *args)
        end
      end
      GenericFunction.new(name, *args)
    end
  end
end
