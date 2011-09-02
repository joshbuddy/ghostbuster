phantom.test.root = "http://127.0.0.1:4567"

phantom.test.before ->
  @var = 'sample'
  @succeed()

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

phantom.test.add "Simple form with specified max test duration", total: 2, ->
  @get '/form', ->
    @wait 1, ->
      @succeed()

phantom.test.add "Before block var", ->
  @get '/form', ->
    @body.input "#in", @var
    @body.click "#btn"
    @body.assertFirst '#out', (out) ->
      out.innerHTML == 'sample'
    @succeed()
