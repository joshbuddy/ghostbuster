class Test
  constructor: (@runner, @name, @maxDuration, @testBody) ->
    @page = new WebPage()
    if @runner.useScreenshots()
      @page.viewportSize = @runner.viewportDimensions()
    @page.onConsoleMessage = (msg) ->
      console.log "PAGE CONSOLE: #{msg}"
    @page.onAlert = (msg) => @setLastError(msg)
    @lastError = null
    @assertions = []
    @seenCallbacks = []
    @assertionIndex = 0
  nameForRender: ->
    name = "#{@runner.suite.screenshot_dir}/#{@runner.nameForRender()}-#{@name.toLowerCase()}"
    name = name.replace(///\s///g, '_')
    name = name.replace(///'///g, '')
    "#{name}-#{++@assertionIndex}.png"
  getLastError: -> @runner.lastErrors[@name]
  resetLastError: -> delete @runner.lastErrors[@name]
  setLastError: (error) ->
    @runner.lastErrors[@name] = error
  waitForAssertions: (whenDone) ->
    @stopTestTimer()
    if @assertions.length == 0
      @startTestTimer()
      whenDone.call(this)
    else
      test = this
      waiting = ->
        test.waitForAssertions(whenDone)
      setTimeout waiting, 10
  actuallyRun: -> true
  run: (callback) ->
    @startTestTimer()
    @runWithFunction(@testBody, callback)
  stopTestTimer: ->
    if @testTimer?
      clearTimeout @testTimer
      @testTimer = null
  startTestTimer: ->
    test = this
    @testTimer ||= setTimeout (->
      test.fail("This test took too long")
    ), @maxDuration
  runWithFunction: (fn, @callback) ->
    fn.call(this)
  get: (path, opts, getCallback) ->
    unless getCallback?
      getCallback = opts
      opts = {}
    @waitForAssertions ->
      test = this
      fatalCallback = ->
        test.fail("The request for #{test.runner.normalizePath(path)} timed out")
      fatal = setTimeout fatalCallback, if opts.total then opts.total * 1000 else 1000
      loadedCallback = (status) ->
        clearTimeout fatal
        return if test.seenCallbacks.indexOf(getCallback) != -1
        test.seenCallbacks.push getCallback # traversing links causes this to get re-fired.
        if test.runner.useScreenshots()
          test.page.render test.nameForRender()
        switch status
          when 'success'
            test.body = new Body(test)
            getCallback.call(test) if getCallback
          when 'fail'
            test.fail("The request for #{test.runner.normalizePath(path)} failed")
      @page.open @runner.normalizePath(path), loadedCallback
  succeed: ->
    @waitForAssertions ->
      @stopTestTimer()
      @callback(true)
  fail: (msg) ->
    @stopTestTimer()
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
      test.stopTestTimer()
      fatalCallback = ->
        if test.runner.useScreenshots()
          test.page.render test.nameForRender()
        test.fail(test.getLastError() || "This assertion failed to complete.")
      @fatal = setTimeout(fatalCallback, assertion.totalTime)
    @fetcher.call test, (val) ->
      assertion.count++
      if val == true
        test.resetLastError()
        test.startTestTimer()
        test.assertions.splice(test.assertions.indexOf(assertion), 1)
        clearTimeout assertion.fatal
        if test.runner.useScreenshots()
          test.page.render test.nameForRender()
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

  click: (selector, opts) ->
    opts ||= {}
    test = @test
    @test.assert opts, (withValue) ->
      idx = opts.index || 0
      eval "
        var evaluator = function() {
          var targets = document.querySelectorAll('#{selector}'),
              evt = document.createEvent('MouseEvents'),
              idx = #{idx};
          evt.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null); 
          if (idx < targets.length) {
            targets[idx].dispatchEvent(evt);
            return true;
          } else {
            alert('Couldn\\'t find element #{idx} for selector #{selector}');
            return false;
          }
        };
      "
      withValue @page.evaluate(evaluator)

  assertCount: (selector, opts, assertionCallback) ->
    unless assertionCallback?
      assertionCallback = opts
      opts = {}
    test = @test
    @test.assert opts, (withValue) ->
      assertionDescription = if opts.name then "\"#{opts.name}\"" else "for selector #{selector}"
      alerter = if test.getLastError()? then "" else "alert('Assert count #{assertionDescription} did not meet expectations, last count is '+count);"
      eval "
        var evaluator = function() {
          try {
            var assertionCallback = #{assertionCallback.toString()};
            var count = document.querySelectorAll('#{selector}').length;
            var ret = assertionCallback(count);
            if (ret) {
              return true;
            } else {
              #{alerter}
              return false;
            }
          } catch(e) {
            var err = 'Assert count for selector #{selector} encountered an unexpected error:'+e;
            console.log(err);
            alert(err);
            return false;
          }
        };
      "
      withValue @page.evaluate(evaluator)

  assertLocation: (path, opts) ->
    opts ||= {}
    test = @test
    location = @test.runner.normalizePath(path)
    @test.assert opts, (withValue) ->
      assertionDescription = if opts.name then " \"#{opts.name}\"" else ""
      alerter = if test.getLastError()? then "" else "alert('Assert location#{assertionDescription} failed: Excepted #{location}, got '+currentLocation);"
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
      assertionDescription = if opts.name then "\"#{opts.name}\"" else "for selector #{selector}"
      alerter = if test.getLastError()? then "" else "alert('Assert first #{assertionDescription} did not meet expectations');"
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
      assertionDescription = if opts.name then "\"#{opts.name}\"" else "for selector #{selector}"
      eval "
        var evaluator = function() {
          try {
            var assertionCallback = #{assertionCallback.toString()};
            var list = document.querySelectorAll('#{selector}');
            if (list.length == 0) throw('list is empty');
            for (var i=0; i != list.length; i++) {
              if (!assertionCallback(list[i], i)) {
                alert('Assert all #{assertionDescription} on item '+i+' didn\\'t meet expectations');
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

  assertCountAndAll: (selector, count, opts, assertionCallback) ->
    @assertCount selector, opts, (c) -> c == count
    @assertAll selector, opts, assertionCallback

class PendingTest
  constructor: (@runner, @name) ->
  run: (callback) -> callback('pending')
  actuallyRun: -> false

class TestFile
  constructor: (@suite, @name) ->
    @tests = []
    @lastErrors = {}
    @befores = []
    @afters = []
  nameForRender: -> @name.toLowerCase()
  useScreenshots: -> @suite.screenshots
  viewportDimensions: -> width: @suite.screenshot_x, height: @suite.screenshot_y
  normalizePath: (path) -> if path.match(/^http/) then path else "#{@root}#{path}"
  addPending: (name, body) -> @tests.push new PendingTest(this, name)
  before: (body) -> @befores.push(body)
  after: (body) -> @afters.push(body)
  add: (name, opts, body) ->
    unless body?
      body = opts
      opts = {}
    for test in @tests
      throw("Identically named test already exists for name #{name} in #{@name}") if test.name == name
    maxDuration = (opts.total || 5) * 1000
    @tests.push new Test(this, name, maxDuration, body)
  run: (callback, idx) ->
    throw "No root is defined" unless @root?
    testFile = this
    testStates = {}
    nextTest = (count) ->
      if count >= testFile.tests.length
        testFile.report(testStates)
        callback()
      else
        test = testFile.tests[count]
        if test.actuallyRun()
          processBefore = (idx, callback) ->
            if testFile.befores[idx]?
              test.runWithFunction testFile.befores[idx], ->
                processBefore(idx + 1, callback)
            else
              callback()
            return
          processBefore 0, ->
            try
              test.run (state, msg) ->
                testFile.lastErrors[test.name] = msg
                testStates[test.name] = state
                nextTest(count + 1)
            catch e
              test.stopTestTimer()
              testFile.lastErrors[test.name] = e.toString()
              testStates[test.name] = false
              nextTest(count + 1)
            finally
              after.call(test) for after in testFile.afters
        else
          test.run (state) ->
            testStates[test.name] = state
            nextTest(count + 1)
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

console.log "Running tests..."

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
    if phantom.version.major == 1 and phantom.version.minor == 3
      @screenshots    = @args[0] == 'true'
      @screenshot_x   = @args[1]
      @screenshot_y   = @args[2]
      @screenshot_dir = @args[3]
      count = 4
      suite = this
      runNextTest = ->
        if suite.args.length == count
          console.log "#{suite.success} success, #{suite.failure} failure, #{suite.pending} pending"
          phantom.exit (if suite.failure == 0 then 0 else 1)
        else
          testFile = suite.args[count]
          phantom.test = new TestFile(suite, testFile)
          if phantom.injectJs(testFile)
            try
              phantom.test.run ->
                count++
                runNextTest()
            catch e
              console.log "For \033[1m#{testFile}\033[0m"
              console.log "  \033[31m\u2717\033[0m #{e.toString()}"
              suite.failure++
              count++
              runNextTest()
          else
            console.log "Unable to load #{testFile}"
      runNextTest()
    else
      console.log "Phantom version must be 1.3.x"
      phantom.exit 1

if phantom.args.length == 0
  console.log("You need to specify a test file")
else
  suite = new TestSuite(phantom.args)
  suite.run()
