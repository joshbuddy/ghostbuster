phantom.test.root = "http://127.0.0.1:4567"


phantom.test.add "This test will explode!", ->
  throw "I hate you!"

phantom.test.add "This test has no succeed", ->
  @get '/form', ->
    "so, like, this test sucks"

phantom.test.add "This test has a custom assertion name", ->
  @get '/form', ->
    @body.assertFirst '#out', name: "custom assertion name", (out) ->
      out.innerHTML == 'this definitely is NOT my input'
    @succeed()

phantom.test.add "This test sets its max test duration too low", total: 1, ->
  @get '/form', ->
    @wait 2, ->
      @succeed()
