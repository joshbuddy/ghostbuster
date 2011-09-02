phantom.test.root = "http://127.0.0.1:4567"

phantom.test.add "Simple index", ->
  @get '/', ->
    @body.assertFirst 'p', (p) ->
      p.innerHTML == 'This is my paragraph'
    @body.assertAll 'ul li', (li, idx) ->
      li.innerHTML == "List item #{idx + 1}"
    @body.assertCountAndAll 'a', 1, (a, idx) ->
      a.href == 'http://127.0.0.1:4567/form'
    @succeed()

phantom.test.add "Simple slow index", ->
  @get '/slow-index', total: 3, ->
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

