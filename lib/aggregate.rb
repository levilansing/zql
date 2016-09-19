module ZQL
  class Aggregate
    prepend Token
    prepend Aliasable
    include Algebraic
    include Expressable

    def initialize(*args)
      ZQL.use args
      @type = args.shift
      param = args.shift
      if param.to_s == 'distinct' || param.to_s == 'all'
        @option = param
        param = args.shift
      end
      @what = param
      @tail = args
    end

    def to_sql
      what = ZQL.ref(@what).to_sql
      what = "#{@option.to_s.upcase} #{what}" if @option
      "#{@type}(#{what})"
    end
  end
end
