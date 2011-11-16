# Ghostbuster

Automated browser testing via phantom.js, with all of the pain taken out! That means you get a *real browser*, with a *real DOM*, and can do *real testing*!

## Installation

To install first `gem install ghostbuster`. Once you've done that, you can run `setup-ghostbuster`. Right now this only works on Mac, so, otherwise, ghostbuster will look for a copy of the `phantomjs` binary in `~/.ghostbuster`.

## Usage

### Standalone

Once installed, you can simply use `ghostbuster [path/to/Ghostfile]` to run your tests.

### Rake

As well, you can install Ghostbuster to run as a rake task. To do this, add this to your `Rakefile`:

    require 'ghostbuster/install_rake'

### Configuration via Ghostfile

Your `Ghostfile` handles your configuration. To set the pattern use:

    ghost.pattern = "test_*.{js,coffee}" # this is the default

To enable (or disable) screenshots use:

    ghost.take_screenshots! # or #do_not_take_screenshots! defaults to take_screenshots!

To set the directory your screenshots will save to use:

    ghost.screenshot_dir = '.'

To set the dimensions for the screenshots use:

    ghost.screenshot_dimensions 800, 2000 # width, height

To set the command for starting your server use:

    ghost.start_command "./start.sh"

To set the timeout in seconds for the start_command to complete use:

    ghost.start_wait = 2   # this is the default

To set the command for stopping your server use:

    ghost.stop_command "./stop.sh"

To set the location of your phantomjs binary, use:

    ghost.phantom_bin = File.join(ENV['HOME'], '.ghostbuster', 'phantomjs')

If no Ghostfile is found, it will simply use the defaults.

### Output

You should get some output that looks something like this.

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
      ◐ Form should do more things

Your test directory should look something like this:

    ghost_tests/start.sh       # Used to start your web application
    ghost_tests/stop.sh        # Used to stop your web application
    ghost_tests/test_*.coffee  # Your tests
    
Look inside `ghost` to see some examples of what actual tests would look like. Let's dive into a couple of simple examples.

Here is one in Coffeescript.

    phantom.test.root = "http://127.0.0.1:4567" # you must specify your root.

    phantom.test.add "Simple index", ->         # this adds a test
      @get '/', ->                              # this will get your a path relative to your root
        @body.assertFirst 'p', (p) ->           # this asserts the first paragraph's inner text
          p.innerHTML == 'This is my paragraph' # is 'This is my paragraph'
        @body.assertAll 'ul li', (li, idx) ->
          li.innerHTML == "List item #{idx + 1}"
        @succeed()                              # all tests must succeed

Here is the same test in Javascript.

    phantom.test.root = "http://127.0.0.1:4567";  // you must specify your root.

    phantom.test.add("Simple index", function() { // this adds a test
      this.get('/', function() {                  // this will get your a path relative to your root
        // this asserts the first paragraph's inner text
        this.body.assertFirst('p', function(p) { return p.innerHTML == 'This is my paragraph'});
        // this asserts all li's have the test, List item {num}
        this.body.assertAll('ul li', function(li, idx) { return li.innerHTML == "List item "+(idx + 1)});
        this.succeed();
      });                                         
    });

## Page Controls

The following methods are available within your test.

### get

*Arguments*: location, [options], callback

This location will be relative to your root if it doesn't start with "http". Your callback will be called when the document is ready.

### click

*Arguments*: selector, [index]

This will click the nth element matching the selector. If no index is specified it uses the first one found.

### clickFollow

*Arguments*: selector, [index or options]

This will click the nth element matching the selector and assert the location changed. If no index is specified it uses the first one found.
If no path option is given, it will merely assert that the location changed.

### input

*Arguments*: selector, text

This will fill in the matching form elements with the text given.

### select

*Arguments*: selector, newValue

This will set a select box to a given value

### wait

*Arguments*: seconds, callback

This will wait `seconds` secs and then call your callback.

## Assertions

Assertions are run in order, and only one assertion at a time can run. An assertion will have at most one second to complete. If you want to change the total amount of time an assertion will take, you can supply that time.

    @body.assertFirst 'p', total: 3, (p) ->           # this asserts the first paragraph's inner text

The options for all assertions currently accepts `total`, which is the total amount of time this assertion will run for in seconds.

The available assertion function are available on `body`:

### assertFirst

*Arguments*: selector, [options], callback

The callback will be called with the first matching DOM element for the selector. The callback must return `true` if this assertion is met.

### assertAll

*Arguments*: selector, [options], callback

The callback will be called for each matching DOM element for the selector. The arguments supplied to the callback is the DOM element and the index (starting at 0). The callback must return `true` if this assertion is met.

### assertLocation

*Arguments*: location, [options]

This assertion will attempt to match the current browser location. If your location does not start with `http`, it will be considered relative to the root of your test.

### refuteLocation

*Arguments*: location, [options]

This assertion will attempt to refute the current browser location. If your location does not start with `http`, it will be considered relative to the root of your test.

### assertCount

*Arguments*: selector, [options], callback

This callback will be called with the number of matching DOM elements for this selector. The callback must return `true` if this assertion is met.

### assertCountAndAll

*Arguments*: selector, count, [options], callback

The callback will be called for each matching DOM element for the selector. It will only be called if the number of matching elements is equal to `count`. The arguments supplied to the callback is the DOM element and the index (starting at 0). The callback must return `true` if this assertion is met.

## Before and After

You can add an arbitrary number of before and after blocks to be run within the context of your test. Simply call `before` and `after` on your test to add them. You have to call @succeed in the before block to continue processing your test.

    phantom.test.before ->
      # do some setup
      @succeed()

    phantom.test.after ->
      # do some teardown
