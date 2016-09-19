module ZQL
  class AlgebraicExpression
    include Token
    prepend Aliasable
    include Algebraic
    include Expressable

    PREFIX_OPERATORS = Set[:-@, :abs]

    def initialize(left, right, operator)
      @left = ZQL.use left
      @right = ZQL.use right
      @operator = operator
      @encapsulate_when_aliased = true
    end

    def operator
      case @operator
      when :abs then '@ '
      when :sqrt then '|/'
      when :pow then '^'
      when :-@ then '-'
      else @operator.to_s
      end
    end

    def to_sql
      if PREFIX_OPERATORS.include?(@operator)
        "#{operator}#{ZQL.encapsulate(@left)}"
      else
        "#{ZQL.encapsulate(@left)} #{operator} #{ZQL.encapsulate(@right)}"
      end
    end
  end
end
