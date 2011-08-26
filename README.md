# Ghostbuster

Automated browser testing via phantom.js, with all of the pain taken out!

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