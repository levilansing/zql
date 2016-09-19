module ZQL
  class Context
    class Operation
      attr_reader :operation, :context
      def initialize(operation, context = nil)
        @operation = operation
        @context = context
      end

      def perform
        case operation
        when :push then ZQL.push_context(@context)
        when :pop  then ZQL.pop_context
        end
      end
    end

    def ref(identifier)
      identifier
    end
  end
end
