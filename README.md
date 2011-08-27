# Ghostbuster

Automated browser testing via phantom.js, with all of the pain taken out! That means you get a *real browser*, with a *real DOM*, and can do *real testing*!

## Installation

To install first `gem install ghostbuster`. Once you've done that, you can run `setup-ghostbuster`. Right now this only works on Mac, so, otherwise, ghostbuster will look for a copy of the `phantomjs` binary in `~/.ghostbuster`.

## Usage

Once installed, you can simply use `ghostbuster path/to/tests` to run your tests. You should get some output that looks something liek this.

~~~~

    GhostBuster
    For /Users/joshbuddy/Development/ghostbuster/ghost/test_ghost.coffee
      ✓ Simple index
      ✓ Form input
      ✓ Link traversal
      ✗ Bad link traversal
        Assert location failed: Excepted http://127.0.0.1:4567/not-correct, got http://127.0.0.1:4567/
      ✗ Form input not equal
        Assert first for selector #out did not meet expectations

    For /Users/joshbuddy/Development/ghostbuster/ghost/test_ghostmore.coffee
      ✓ Simple form
      • Form should do more things

~~~~

Your test directory should look something like this:

    ghost_tests/start.sh       # Used to start your web application
    ghost_tests/stop.sh        # Used to stop your web application
    ghost_tests/test_*.coffee  # Your tests
    
Look inside `ghost` to see some examples of what actual tests would look like. Let's dive into a couple of simple examples.

~~~~

    phantom.test.root = "http://127.0.0.1:4567" # you must specify your root.

    phantom.test.add "Simple index", ->         # this adds a test
      @get '/', ->                              # this will get your a path relative to your root
        @body.assertFirst 'p', (p) ->           # this asserts the first paragraph's inner text
          p.innerHTML == 'This is my paragraph' # is 'This is my paragraph'
        @body.assertAll 'ul li', (li, idx) ->
          li.innerHTML == "List item #{idx + 1}"
        @succeed()                              # all tests must succeed

~~~~

To use this within rake, just put `require 'ghostbuster/install_rake'` in your Rakefile.

## Assertions

Assertions are run in order, and only one assertion at a time can run. An assertion will have at most one second to complete. If you want to change the total amount of time an assertion will take, you can supply that time.

~~~~
    @body.assertFirst 'p', total: 3, (p) ->           # this asserts the first paragraph's inner text
~~~~

The available assertions are:

* _assertFirst_ : This asserts for the first matching DOM element
* _assertAll_ : This asserts for the each matching DOM element
* _assertLocation_ : This asserts the current browser location

The closures passed for matching have access to the real DOM node, however, they do not have any access to the outside context. They must return true if the assertion is passed, anything else will be interpreted as failure.

## Before and after

You can add an arbitrary number of before and after blocks to be run within the context of your test. Simple call `before` and `after` on your test to add them.

~~~~
    phantom.test.before ->
      # do some setup

    phantom.test.after ->
      # do some teardown
~~~~
