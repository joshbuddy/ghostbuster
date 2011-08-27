class Test
  constructor: (@runner, @name, @testBody) ->
    @page = new WebPage()
    @page.onConsoleMessage = (msg) ->
      console.log "PAGE CONSOLE: #{msg}"
    @page.onAlert = (msg) => @setLastError(msg)
    @lastError = null
    @assertions = []
    @seenCallbacks = []
  getLastError: -> @runner.lastErrors[@name]
  resetLastError: -> delete @runner.lastErrors[@name]
  setLastError: (error) ->
    @runner.lastErrors[@name] = error
  waitForAssertions: (whenDone) ->
    if @assertions.length == 0
      whenDone.call(this)
    else
      test = this
      waiting = ->
        test.waitForAssertions(whenDone)
      setTimeout waiting, 10
  run: (@callback) ->
    @testBody.call(this)
  get: (path, getCallback) ->
    @waitForAssertions ->
      test = this
      loadedCallback = (status) ->
        return if test.seenCallbacks.indexOf(getCallback) != -1
        test.seenCallbacks.push getCallback # traversing links causes this to get re-fired.
        switch status
          when 'success'
            test.body = new Body(test)
            getCallback.call(test) if getCallback
          when 'fail'
            test.fail()
      @page.open @runner.normalizePath(path), loadedCallback
  succeed: ->
    @waitForAssertions ->
      @callback(true)
  fail: (msg) ->
    @callback(false, msg)
  assert: (opts, valueFetcher) ->
    @assertions.push(new Assertion(this, opts, valueFetcher))
    @assertions[0].start() if @assertions.length == 1
  wait: (time, callback) ->
    test = this
    setTimeout (-> callback.call(test)), time * 1000

class Assertion
  constructor: (@test, @opts, @fetcher) ->
    @count = 0
    @totalTime = if @opts['total'] then @opts['total'] * 1000 else 1000
    @everyTime = if @opts['every'] then @opts['every'] else 75
  start: ->
    test              = @test
    assertion         = this
    failedCallback    = ->
      assertion.start()
    if @count == 0
      fatalCallback = ->
        test.fail(test.getLastError() || "This assertion failed to complete.")
      @fatal = setTimeout(fatalCallback, assertion.totalTime)
    @fetcher.call test, (val) ->
      assertion.count++
      if val == true
        test.resetLastError()
        test.assertions.splice(test.assertions.indexOf(assertion), 1)
        clearTimeout assertion.fatal
        if test.assertions.length > 0
          test.assertions[0].start()
      else
        setTimeout(failedCallback, test.everyTime)
        
class Body
  constructor: (@test) ->
  input: (selector, value) ->
    eval "
      var input = function() {
        var value = '#{value}';
        var list = document.querySelectorAll('#{selector}');
        for(var i = 0; i != list.length; i++) {
          list[i].value = value;
        }
      }
    "
    @test.page.evaluate(input)

  click: (selector) ->
    eval "
      var fn = function() {
        var targets = document.querySelectorAll('#{selector}'),
            evt = document.createEvent('MouseEvents'), 
            i, len; 
        evt.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null); 

        for ( i = 0, len = targets.length; i < len; ++i ) { 
            targets[i].dispatchEvent(evt);     
        } 
      };
    "
    @test.page.evaluate(fn)

  assertLocation: (path, opts) ->
    opts ||= {}
    test = @test
    location = @test.runner.normalizePath(path)
    @test.assert opts, (withValue) ->
      alerter = if test.getLastError()? then "" else "alert('Assert location failed: Excepted #{location}, got '+currentLocation);"
      eval "
        var fn = function() {
          var currentLocation = window.location.href;
          if (window.location.href === '#{location}') {
            return true;
          } else {
            #{alerter}
            return false;
          }
        }
      "
      withValue @page.evaluate(fn)

  assertFirst: (selector, opts, assertionCallback) ->
    unless assertionCallback?
      assertionCallback = opts
      opts = {}
    test = @test
    @test.assert opts, (withValue) ->
      alerter = if test.getLastError()? then "" else "alert('Assert first for selector #{selector} did not meet expectations');"
      eval "
        var evaluator = function() {
          try {
            var assertionCallback = #{assertionCallback.toString()};
            var ret = assertionCallback(document.querySelector('#{selector}'));
            if (ret) {
              return true;
            } else {
              #{alerter}
              return false;
            }
          } catch(e) {
            var err = 'Assert first for selector #{selector} encountered an unexpected error:'+e;
            console.log(err);
            alert(err);
            return false;
          }
        };
      "
      withValue @page.evaluate(evaluator)

  assertAll: (selector, opts, assertionCallback) ->
    unless assertionCallback?
      assertionCallback = opts
      opts = {}
    @test.assert opts, (withValue) ->
      eval "
        var evaluator = function() {
          try {
            var assertionCallback = #{assertionCallback.toString()};
            var list = document.querySelectorAll('#{selector}');
            if (list.length == 0) throw('list is empty');
            for (var i=0; i != list.length; i++) {
              if (!assertionCallback(list[i], i)) {
                alert('Assert all for selector #{selector} on item '+i+' didn\\'t meet expectations');
                return false;
              }
            }
            return true;
          } catch(e) {
            alert('Assert all for selector #{selector} encountered an unexpected error:'+e);
            return false;
          }
        };
      "
      withValue @page.evaluate(evaluator)

class PendingTest
  constructor: (@runner, @name) ->
  run: (callback) -> callback('pending')

class TestFile
  constructor: (@suite, @name) ->
    @tests = []
    @lastErrors = {}
    @befores = []
    @afters = []
  normalizePath: (path) -> if path.match(/^http/) then path else "#{@root}#{path}"
  addPending: (name, body) -> @tests.push new PendingTest(this, name)
  before: (body) -> @befores.push(body)
  after: (body) -> @afters.push(body)
  add: (name, body) ->
    for test in @tests
      throw("Identically named test already exists for name #{name} in #{@name}") if test.name == name
    @tests.push new Test(this, name, body)
  run: (callback) ->
    throw "No root is defined" unless @root?
    testFile = this
    testStates = {}
    nextTest = (count) ->
      test = testFile.tests[count]
      before.call(test) for before in testFile.befores
      try
        if count < testFile.tests.length
          test.run (state) ->
            testStates[test.name] = state
            nextTest(count + 1)
        else
          testFile.report(testStates)
          callback()
      catch e
        testFile.lastErrors[test.name] = e.toString()
        testStates[test.name] = false
        nextTest(count + 1)
      finally
        after.call(test) for before in testFile.afters
    nextTest(0)
  report: (testStates) ->
    success = 0
    failure = 0
    pending = 0
    console.log "For \033[1m#{@name}\033[0m"
    for name, state of testStates
      if state == true
        success++
        console.log "  \033[32m\u2713\033[0m #{name}"
      else if state == 'pending'
        pending++
        console.log "  \033[33m\u25d0\033[0m #{name}"
      else
        failure++
        console.log "  \033[31m\u2717\033[0m #{name}\n    #{@lastErrors[name] || "There was a problem"}"
    console.log ""
    @suite.report(success, failure, pending)
console.log "GhostBuster"

class TestSuite
  constructor: (@args) ->
    @success = 0
    @failure = 0
    @pending = 0
  report: (success, failure, pending) ->
    @success += success
    @failure += failure
    @pending += pending
  run: ->
    count = 0
    suite = this
    runNextTest = ->
      if suite.args.length == count
        console.log "#{suite.success} success, #{suite.failure} failure, #{suite.pending} pending"
        phantom.exit (if suite.failure == 0 then 0 else 1)
      else
        testFile = suite.args[count]
        phantom.test = new TestFile(suite, testFile)
        if phantom.injectJs(testFile)
          phantom.test.run ->
            count++
            runNextTest()
        else
          console.log "Unable to load #{testFile}"
    runNextTest()

if phantom.args.length == 0
  console.log("You need to specify a test file")
else
  suite = new TestSuite(phantom.args)
  suite.run()
