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
  include EM::MiniTest::Spec

  describe ".all" do
    it "returns deferrable" do
      d = When.all([When.deferred(42)])
      assert d.respond_to?(:callback)
      assert d.respond_to?(:errback)
    end

    it "resolves immediately if no promises" do
      d = When.all([])
      d.callback do |results|
        assert_equal [], results
        done!
      end
      wait!
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
