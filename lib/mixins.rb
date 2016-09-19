module ZQL
  class AlgebraicExpression; end
  class Condition; end
  class Expression < Condition; end

  module Expressable
    def ==(other)
      Expressable.condition(self, other, :==)
    end

    def !=(other)
      Expressable.condition(self, other, :!=)
    end

    def <(other)
      Expressable.condition(self, other, :<)
    end

    def >(other)
      Expressable.condition(self, other, :>)
    end

    def <=(other)
      Expressable.condition(self, other, :<=)
    end

    def >=(other)
      Expressable.condition(self, other, :>=)
    end

    def is_null?
      Expressable.condition(self, nil, :null?)
    end

    def not_null?
      Expressable.condition(self, nil, :not_null?)
    end

    def and(*other)
      ZQL.add Expression.new(self, other, :and)
    end

    def or(*other)
      ZQL.add Expression.new(self, other, :or)
    end

    def !
      ZQL.add Expression.new(nil, self, :not)
    end
    alias :is_not_null? :not_null?

    def self.condition(left, right, operator)
      if right.is_a?(Array)
        if operator == :==
          fn = ExplicitFunction.new(:in, right.length, *right).enclose!
          ZQL.add Condition.new(left, fn, nil)
        elsif operator == :!=
          fn = ExplicitFunction.new(:'not in', right.length, *right).enclose!
          ZQL.add Condition.new(left, fn, nil)
        else
          raise GrammarException, "right side of operator #{operator} cannot be an array"
        end
      else
        ZQL.add Condition.new(left, right, operator)
      end
    end
  end

  module Algebraic
    def +(other)
      ZQL.add AlgebraicExpression.new(self, other, :+)
    end

    def -(other)
      ZQL.add AlgebraicExpression.new(self, other, :-)
    end

    def /(other)
      ZQL.add AlgebraicExpression.new(self, other, :/)
    end

    def *(*other)
      if other.length == 1
        ZQL.add AlgebraicExpression.new(self, other.first, :*)
      elsif defined?(super)
        super
      end
    end

    def %(other)
      ZQL.add AlgebraicExpression.new(self, other, :%)
    end

    def -@
      # unary minus
      ZQL.add AlgebraicExpression.new(self, nil, :-@)
    end

    def **(other)
      ZQL.add AlgebraicExpression.new(self, other, :pow)
    end

    def sqrt(other)
      ZQL.add AlgebraicExpression.new(self, other, :sqrt)
    end

    def abs
      ZQL.add AlgebraicExpression.new(self, nil, :abs)
    end

    def <<(other)
      ZQL.add AlgebraicExpression.new(self, other, :<<)
    end

    def >>(other)
      ZQL.add AlgebraicExpression.new(self, other, :>>)
    end
  end

  module Aliasable
    def as(alias_name)
      @alias_name = ZQL.use alias_name
      self
    end

    def aliased?
      !@alias_name.nil?
    end

    def to_sql
      if aliased?
        if @encapsulate_when_aliased
          "(#{super}) as #{ZQL.encapsulate(@alias_name)}"
        else
          "#{super} as #{ZQL.encapsulate(@alias_name)}"
        end
      else
        super
      end
    end
  end
end

require 'algebraic_expression'
require 'condition'
require 'expression'
