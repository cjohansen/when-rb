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
require "test_helper"
require "when"

describe When do
  describe "When" do
    it "returns promise" do
      promise = When(42)
      assert promise.respond_to?(:callback)
      assert promise.respond_to?(:errback)
    end

    it "resolves promise with value" do
      promise = When(42)
      called_back = false
      promise.callback do |value|
        assert_equal 42, value
        called_back = true
      end

      assert called_back
    end
  end

  describe "resolve" do
    it "returns resolved promise" do
      called_back = false
      When.resolve(42).callback do |num|
        assert_equal 42, num
        called_back = true
      end

      assert called_back
    end
  end

  describe "reject" do
    it "returns rejected promise" do
      called_back = false
      When.reject(42).errback do |num|
        assert_equal 42, num
        called_back = true
      end

      assert called_back
    end
  end

  describe "defer" do
    it "creates deferred" do
      deferred = When.defer
      assert deferred.respond_to?(:callback)
      assert deferred.respond_to?(:errback)
      assert deferred.respond_to?(:resolve)
      assert deferred.respond_to?(:reject)
    end

    it "resolves promise through resolver" do
      deferred = When.defer
      called_back = false
      deferred.promise.callback { called_back = true }
      assert !called_back
      deferred.resolver.resolve
      assert called_back
    end

    it "aliases then to callback" do
      deferred = When.defer
      called_back = false
      deferred.promise.then { called_back = true }
      deferred.resolver.resolve
      assert called_back
    end

    it "resolves promise through deferred" do
      deferred = When.defer
      called_back = false
      deferred.promise.callback { called_back = true }
      assert !called_back
      deferred.resolve
      assert called_back
    end

    it "resolves deferred through deferred" do
      deferred = When.defer
      called_back = false
      deferred.callback { called_back = true }
      assert !called_back
      deferred.resolve
      assert called_back
    end

    it "raises if already resolved" do
      deferred = When.defer
      deferred.resolve
      assert_raises(When::AlreadyResolvedError) do
        deferred.resolve
      end
    end

    it "rejects promise through reject" do
      deferred = When.defer
      called_back = false
      deferred.promise.errback { called_back = true }
      assert !called_back
      deferred.resolver.reject
      assert called_back
    end

    it "rejects promise through deferred" do
      deferred = When.defer
      called_back = false
      deferred.promise.errback { called_back = true }
      assert !called_back
      deferred.reject
      assert called_back
    end

    it "rejects deferred through deferred" do
      deferred = When.defer
      called_back = false
      deferred.errback { called_back = true }
      assert !called_back
      deferred.reject
      assert called_back
    end

    it "raises if already rejectd" do
      deferred = When.defer
      deferred.reject
      assert_raises(When::AlreadyResolvedError) do
        deferred.reject
      end
    end
  end

  describe ".all" do
    it "returns deferrable" do
      d = When.all([When(42)])
      assert d.respond_to?(:callback)
      assert d.respond_to?(:errback)
    end

    it "resolves immediately if no promises" do
      d = When.all([])
      called_back = false
      d.callback do |results|
        assert_equal [], results
        called_back = true
      end
      assert called_back
    end

    it "resolves when single deferrable resolves" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      resolved = false
      d.callback { |results| resolved = true }

      assert !resolved
      deferred.resolve(42)
      assert resolved
    end

    it "resolves when all deferrables are resolved" do
      deferreds = [When::Deferred.new, When::Deferred.new, When::Deferred.new]
      d = When.all(deferreds.map(&:promise))
      resolved = false
      d.callback { |results| resolved = true }

      assert !resolved
      deferreds[0].resolve(42)
      assert !resolved
      deferreds[1].resolve(13)
      assert !resolved
      deferreds[2].resolve(3)
      assert resolved
    end

    it "rejects when single deferrable rejects" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      rejected = false
      d.errback { |results| rejected = true }

      assert !rejected
      deferred.reject(StandardError.new)
      assert rejected
    end

    it "rejects on first rejection" do
      deferreds = [When::Deferred.new, When::Deferred.new, When::Deferred.new]
      d = When.all(deferreds.map(&:promise))
      rejected = false
      d.errback { |results| rejected = true }

      deferreds[0].resolve(42)
      deferreds[2].reject(StandardError.new)
      deferreds[1].resolve(13)

      assert rejected
    end

    it "proxies resolution vaule in array" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      results = nil
      d.callback { |res| results = res }

      deferred.resolve(42)
      assert_equal [42], results
    end

    it "orders results like input" do
      deferred1 = When::Deferred.new
      deferred2 = When::Deferred.new
      d = When.all([deferred1.promise, deferred2.promise])
      results = nil
      d.callback { |res| results = res }

      deferred2.resolve(42)
      deferred1.resolve(13)
      assert_equal [13, 42], results
    end
  end
end
