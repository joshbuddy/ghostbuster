phantom.test.root = "http://127.0.0.1:4567"

phantom.test.add "Bad link traversal", ->
  @get '/', ->
    @body.click 'a'
    @body.assertLocation('/not-correct')
    @succeed()
    
phantom.test.add "Bad click selector", ->
  @get '/', ->
    @body.click 'i-just-made-this-up'
    @succeed()

phantom.test.add "Form input not equal", ->
  @get '/form', ->
    @body.input "#in", "this is my input"
    @body.click "#btn"
    @body.assertFirst '#out', (out) ->
      out.innerHTML == 'this is NOT my input'
    @succeed()

phantom.test.addPending "To a non existent page", ->
  @get '/404', ->
    @succeed()

phantom.test.add "To an invalid URL", ->
  @get 'http://127.0.0.1:this-url-is-invalid', ->
    @succeed()
