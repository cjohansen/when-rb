# encoding: utf-8
# --
# The MIT License (MIT)
#
# Copyright (C) 2012 Gitorious AS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#++

module When
  class Promise
    def initialize(deferred); @deferred = deferred; end
    def then(&block); @deferred.then(&block); end
    def callback(&block); @deferred.callback(&block); end
    def errback(&block); @deferred.errback(&block); end
  end

  class Resolver
    def initialize(deferred); @deferred = deferred; end
    def resolve(*args); @deferred.resolve(*args); end
    def reject(*args); @deferred.reject(*args); end
    def resolved?; @deferred.resolved; end
  end

  class Deferred
    attr_reader :resolver, :promise

    def initialize
      @resolution = nil
      @callbacks = { :resolved => [], :rejected => [] }
      @resolver = Resolver.new(self)
      @promise = Promise.new(self)
    end

    def resolve(*args); mark_resolved(:resolved, args); end
    def reject(*args); mark_resolved(:rejected, args); end
    def callback(&block); add_callback(:resolved, block); end
    def then(&block); add_callback(:resolved, block); end
    def errback(&block); add_callback(:rejected, block); end
    def resolved?; !@resolution.nil?; end

    private
    def add_callback(type, block)
      return notify_callbacks({ type => [block] }) if resolved?
      @callbacks[type] << block
    end

    def mark_resolved(state, args)
      raise AlreadyResolvedError.new("Already resolved") if resolved?
      @resolution = [state, args]
      notify_callbacks(@callbacks)
    end

    def notify_callbacks(callbacks)
      blocks = callbacks[@resolution.first] || []
      blocks.each { |cb| cb.call(*@resolution.last) }
    end
  end

  def self.defer
    deferred = Deferred.new
    yield deferred if block_given?
    deferred
  end

  def self.resolve(val)
    deferred = Deferred.new
    deferred.resolve(val)
    deferred.promise
  end

  def self.reject(val)
    deferred = Deferred.new
    deferred.reject(val)
    deferred.promise
  end

  def self.all(promises)
    raise(ArgumentError, "expected enumerable promises") if !promises.is_a?(Enumerable)
    resolved = 0
    results = []
    d = Deferred.new

    attempt_resolution = lambda do |err, res|
      break if d.resolved?
      if err.nil?
        d.resolve(res) if promises.length == resolved
      else
        d.reject(err)
      end
    end

    wait_for_all(promises) do |err, result, index|
      resolved += 1
      results[index] = result
      attempt_resolution.call(err, results)
    end

    attempt_resolution.call(nil, results) if promises.length == 0
    d.promise
  end

  private
  def self.wait_for_all(promises, &block)
    promises.each_with_index do |p, i|
      p.callback do |result|
        block.call(nil, result, i)
      end
      p.errback { |e| block.call(e, nil, i) }
    end
  end

  class AlreadyResolvedError < Exception; end
end

def When(val)
  return val if val.respond_to?(:callback) && val.respond_to?(:errback)
  When.resolve(val)
end
