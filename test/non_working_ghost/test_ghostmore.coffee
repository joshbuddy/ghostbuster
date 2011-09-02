phantom.test.root = "http://127.0.0.1:4567"


phantom.test.add "This test will explode!", ->
  throw "I hate you!"

phantom.test.add "This test has no succeed", ->
  @get '/form', ->
    "so, like, this test sucks"
