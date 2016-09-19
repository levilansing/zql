module ZQL
  class Literal
    include Token
    prepend Aliasable
    include Expressable
    include Algebraic

    def initialize(value)
      @value = value
    end

    def to_s
      @value.to_s
    end

    def to_sql
      @value.to_s
    end

    def nil?
      @value.nil? || @value == 'null'
    end
  end

  class Comma
    # Comma class is a comma placeholder for joining
    def to_sql
      nil
    end
  end
end
