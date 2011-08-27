phantom.test.root = "http://127.0.0.1:4567"

phantom.test.add "Simple form", ->
  @get '/form', ->
    @succeed()

phantom.test.addPending "Form should do more things", ->
  console.log "some thing here.."

phantom.test.add "Simple form with wait", ->
  @get '/form', ->
    @wait 1, ->
      @succeed()
      
phantom.test.add "Slow form", ->
  @get '/slow', ->
    @body.input "#in", "this is my input"
    @body.click "#btn"
    @body.assertFirst '#out', total: 3, (out) ->
      out.innerHTML == 'this is my input'
    @succeed()
