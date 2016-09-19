require 'forwardable'

module ZQL
  class Executor
    include Enumerable
    extend Forwardable
    def_delegators :@execution_list, :each, :count, :length, :pop, :push, :delete

    attr_accessor :context, :execution_list
    def initialize
      @execution_list = []
    end

    def <<(any)
      @execution_list << any
      any
    end

    def delete(token)
      return token unless token.is_a?(Token)
      if @execution_list.last.object_id == token.object_id
        @execution_list.pop
      else
        @execution_list.delete_if do |t|
          t.object_id == token.object_id
        end
      end
      token
    end

    def map_executors
      @execution_list.map do |part|
        if part.is_a? Context::Operation
          part.perform
          nil
        else
          yield(part)
        end
      end
    end

    def compile
      ZQL.begin_compiling

      # TODO: implement compiling schema introspection
      map_executors { |executor| executor.compile if executor.respond_to?(:compile)}

      sql = map_executors do |executor|
        executor.to_sql
      end.compact.join("\n")

      ZQL.end_compiling

      sql + ';'
    end
  end
end
