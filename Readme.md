# When.rb

<a href="http://travis-ci.org/cjohansen/when-rb" class="travis">
  <img src="https://secure.travis-ci.org/cjohansen/when-rb.png">
</a>

This library is a Ruby port of the wonderful JavaScript promise library
[when.js](https://github.com/cujojs/when). The API is kept as close to the
original as possible. In cases where there's a trade-off between 1:1 API
compatibility and "being Ruby-like", the latter is preferred. An example is
`When.defer`, which yields the newly created deferred to a block in Ruby.

This is currently a minimal implementation and the port is being built on a
what-I-need basis.

## API

### `When(value_or_promise)`

Returns a promise. If the value is already a promise, it is returned. Otherwise,
a new promise is created and immediately resolved with the provided value.

### `When.defer`

Create a deferred, equivalent to `When::Deferred.new`. The deferred can be
"split" in its resolver and promise parts for better encapsulation:

```ruby
require "when"
require "eventmachine"

def async
  deferred = When.defer
  EventMachine.defer { deferred.resolver.resolve(42) }
  deferred.promise
end

EventMachine.run do
  async.then do |num
    puts "Got number #{num}"
    EventMachine.stop
  end
end
```

In this example, the returned promise can only register success and failure
callbacks, it can not be used to resolve the deferred.

### `When.resolve(value)`

Creates a deferred and immediately resolves it with `value`, then returns the
promise.

### `When.reject(value)`

Creates a deferred and immediately rejects it with `value`, then returns the
promise.

### `When.all(promises)`

Takes an array of promises/deferreds and returns a promise that will either
reject when the first promise rejects, or resolve when all promises have
resolved.

## Why?

Working with EventMachine, I found that I didn't care to much for its deferrable
implementation. My main objections was:

1. The way it encourages you to extend deferrable types with custom logic to
   create deferrable business objects.
2. (More importantly) How it allows deferrables to be resolved multiple times.


## Installing

`when` ships as a gem:

    $ gem install when

Or in your Gemfile:

    gem "when", "~> 0"

## Contributing

Contributions are welcome. To get started:

    $ git clone git://gitorious.org/gitorious/when.git
    $ cd when
    $ bundle install
    $ rake

When you have fixed a bug/added a feature/done your thing, create a
[clone on Gitorious](http://gitorious.org/gitorious/when-rb) or a
[fork on GitHub](http://github.com/cjohansen/when-rb) and send a
merge request/pull request, whichever you prefer.

Please add tests when adding/altering code, and always make sure all the tests
pass before submitting your contribution.

## License

### The MIT License (MIT)

**Copyright (C) 2012 Gitorious AS**

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
