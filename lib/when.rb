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
require "eventmachine"

module When
  class Promise
    def initialize(deferred = EM::DefaultDeferrable.new)
      @deferred = deferred
    end

    def callback(&block)
      @deferred.callback(&block)
      self
    end

    def errback(&block)
      @deferred.errback(&block)
      self
    end
  end

  class Resolver
    def initialize(deferred = EM::DefaultDeferrable.new)
      @deferred = deferred
      @resolved = false
    end

    def resolve(*args)
      mark_resolved
      @deferred.succeed(*args)
    end

    def reject(*args)
      mark_resolved
      @deferred.fail(*args)
    end

    def resolved?
      @resolved
    end

    private
    def mark_resolved
      raise StandardError.new("Already resolved") if @resolved
      @resolved = true
    end
  end

  class Deferred
    attr_reader :resolver, :promise

    def initialize
      deferred = EM::DefaultDeferrable.new
      @resolver = Resolver.new(deferred)
      @promise = Promise.new(deferred)
    end

    def resolve(*args)
      @resolver.resolve(*args)
    end

    def reject(*args)
      @resolver.reject(*args)
    end

    def callback(&block)
      @promise.callback(&block)
    end

    def errback(&block)
      @promise.errback(&block)
    end

    def resolved?
      @resolver.resolved?
    end

    def self.resolved(value)
      d = self.new
      d.resolve(value)
      d
    end

    def self.rejected(value)
      d = self.new
      d.reject(value)
      d
    end
  end

  def self.defer
    Deferred.new
  end

  def self.deferred(val)
    return val if val.respond_to?(:callback) && val.respond_to?(:errback)
    Deferred.resolved(val).promise
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
end
