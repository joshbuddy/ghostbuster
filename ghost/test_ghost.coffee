phantom.test.root = "http://127.0.0.1:4567"

phantom.test.add "Simple index", ->
  @get '/', ->
    @body.assertFirst 'p', (p) ->
      p.innerHTML == 'This is my paragraph'
    @body.assertAll 'ul li', (li, idx) ->
      li.innerHTML == "List item #{idx + 1}"
    @succeed()

phantom.test.add "Form input", ->
  @get '/form', ->
    @body.input "#in", "this is my input"
    @body.click "#btn"
    @body.assertFirst '#out', (out) ->
      out.innerHTML == 'this is my input'
    @succeed()

phantom.test.add "Link traversal", ->
  @get '/', ->
    @body.click 'a'
    @body.assertLocation('/form')
    @succeed()

phantom.test.add "Bad link traversal", ->
  @get '/', ->
    @body.click 'a'
    @body.assertLocation('/not-correct')
    @succeed()
    
phantom.test.add "Form input not equal", ->
  @get '/form', ->
    @body.input "#in", "this is my input"
    @body.click "#btn"
    @body.assertFirst '#out', (out) ->
      out.innerHTML == 'this is NOT my input'
    @succeed()
