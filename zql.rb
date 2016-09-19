require 'set'

$LOAD_PATH << File.join(__dir__, 'lib')

require 'token'
require 'mixins'
require 'reference'
require 'function'

(Dir['lib/*.rb'] - ['lib/zql.rb']).each { |file| require file }

module ZQL
  class GrammarException < Exception; end

  @state = {}
  def self.state
    @state[Thread.current.object_id] ||= {}
  end

  def self.reset_state
    @state[Thread.current.object_id] = {}
  end

  def self.set_current_template(template)
    state[:template] = template
  end

  def self.current_template
    state[:template]
  end

  def self.begin_compiling
    state[:compiling] = true
  end

  def self.compiling?
    state[:compiling]
  end

  def self.end_compiling
    state[:compiling] = false
  end

  def self.current_executor
    state[:executor]
  end

  def self.set_current_executor(executor)
    state[:executor] = executor
  end

  def self.with_executor(executor)
    prev_executor = self.state[:executor]
    ZQL.set_current_executor(executor)

    yield

    ZQL.set_current_executor(prev_executor)
  end

  def self.use(token)
    if token.is_a?(Array)
      token.each { |t| current_executor.delete(t) }
    else
      current_executor.delete(token)
    end
  end

  def self.add(token)
    current_executor << token
  end

  def self.current_context
    self.state[:contexts] ||= []
    self.state[:contexts].last
  end

  def self.push_context(context)
    self.state[:contexts] ||= []
    self.state[:contexts].push context
    context
  end

  def self.pop_context
    self.state[:contexts]&.pop
  end

  def self.ref(value)
    if value.is_a?(String)
      Reference.new(value)
    elsif value.is_a?(Symbol)
      Reference.new(value.to_s)
    elsif value.kind_of?(Numeric) || value.kind_of?(Fixnum) || value.is_a?(TrueClass) || value.is_a?(FalseClass)
      Literal.new(value)
    elsif value.nil?
      Literal.new('NULL')
    else
      value
    end
  end

  def self.encapsulate(ref)
    ref = ZQL.ref(ref)
    if ref.kind_of?(Literal) || ref.kind_of?(Reference)
      ref.to_sql
    elsif ref.kind_of?(Condition) || ref.kind_of?(Expression)
      "(#{ref.to_sql})"
    elsif ref.kind_of?(Function)
      ref.enclose!.to_sql
    else
      ref.to_sql
    end
  end

  def self.join(tokens)
    tokens.slice_after { |token| token.is_a?(Comma) }.map do |set|
      set.shift if set.first.is_a?(Comma)
      set.map { |token| encapsulate(token) }.compact.join(' ') if set.length > 0
    end.compact.join(', ')
  end
end
