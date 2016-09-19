module ZQL
  class Condition
    include Token
    prepend Aliasable
    include Expressable

    def initialize(left, right, operator)
      @left = ZQL.use left
      @right = ZQL.use right
      @operator = operator
    end

    def operator
      case @operator
      when :== then @right.nil? ? 'is' : '='
      when :!= then @right.nil? ? 'is not' : '!='
      else @operator
      end
    end

    def to_sql
      parts = []
      right_side = @right.is_a?(Array) ? @right : [@right]
      parts.push ZQL.encapsulate(@left) if @left
      right_side.each do |right|
        parts.push operator if @operator
        parts.push ZQL.encapsulate(right) if right || @operator == :== || @operator == :!=
      end
      parts.join(' ')
    end
  end
end
