module ZQL
  module Token

    def method_missing(name, *args)
      return super if ZQL.compiling?
      (@tail ||= []) << Reference.new(name)
      @tail.concat(args)
      self
    end

    def add_to_tail!(tokens)
      (@tail ||= []).concat(tokens)
    end

    def to_sql
      if @tail && @tail.length > 0
        return [super, ZQL.join(@tail)].join(' ')
      end
      super
    end

    def unwind!(collector = [])
      if !@tail || @tail.length == 0
        collector.push(self)
        return collector
      end

      @tail.each_with_index do |token, i|
        collector.push(Comma.new) if i > 0 && !collector.last.is_a?(Comma)
        if token.is_a? Token
          token.unwind!(collector)
        else
          collector.push(token) unless token.is_a?(Comma) && collector.last.is_a?(Comma)
        end
      end
      @tail = nil

      apply_tail!(collector)
      collector.unshift self
      collector
    end

    def apply_tail!(tail)
      while tail.length > 0
        token = tail[0]
        if token.is_a?(GenericFunction) || token.is_a?(Reference)
          method_name = token.to_s.to_sym
          if respond_to?(method_name)
            arity = method(method_name).arity
            if tail.length > arity
              tail.shift
              send(method_name, *tail.shift(arity))
              next
            end
          end
        end
        break
      end
    end
  end
end
