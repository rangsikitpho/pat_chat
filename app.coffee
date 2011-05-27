get '/': -> 
  @name = cookies['name']
  if @name
    render 'index'
  else
    redirect '/login'
  #render 'default'

post '/login': -> 
  puts "Setting name cookie to " + params.name
  response.cookie('name', params.name, {expires: new Date(Date.now() + 3600*24*1000*360), path: "/"})
  redirect '/'

get '/login': -> 
  puts 'normal login'
  render 'login'

get '/logout': ->
  response.clearCookie('name')
  redirect '/'

get '/counter': -> "# of messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  puts "Connected: #{id}"
  broadcast 'connected', id: id

at disconnection: ->
  puts "Disconnected: #{id}"

msg said: ->
  puts "#{@name} said: #{@text}"
  app.counter++
  send 'said', id: id, name: @name, text: @text
  broadcast 'said', id: id, name: @name, text: @text

msg coded: ->
  puts "#{@name} coded: #{@text}"
  app.counter++
  send 'coded', id: id, name: @name, text: @text
  broadcast 'coded', id: id, name: @name, text: @text

client index: ->
  $(document).ready ->
    SyntaxHighlighter.all()
    socket = new io.Socket()

    socket.on 'connect', -> $('#chat').append '<p>Connected</p>'
    socket.on 'disconnect', -> $('#chat').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#chat').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#chat').append "<p>#{msg.said.name}: #{msg.said.text}</p>"
      else if msg.coded then $('#chat').append "<p>#{msg.coded.name} Code: #{msg.coded.text}</p>"

      $("#chat").attr({ scrollTop: $("#chat").attr("scrollHeight") }) # Automaticall scroll to end of div

    $('#chat_form').submit ->
      socket.send JSON.stringify said: {text: $('#chat_box').val(), name: $('#name').val()}
      $('#chat_box').val('').focus()
      false

    $('#code_form').submit ->
      socket.send JSON.stringify coded: {text: $('#code_box').val(), name: $('#name').val()}
      $('#chat_box').val('').focus()
      false

    socket.connect()
    $('#chat_box').focus()

view index: ->
  @title = 'PATchat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/index', '/javascripts/shCore', '/javascripts/shBrushJScript']
  link rel: 'stylesheet', href: '/stylesheets/style.css'
  link rel: 'stylesheet', href: '/stylesheets/shCore.css'
  link rel: 'stylesheet', href: '/stylesheets/shThemeDefault.css'

  div id: 'title', ->
    h1 "#{@title}: #{@name}"
    a href: '/logout', -> 'Logout'

  div id: 'chat', ->
    h2 "Chat"

  div id: 'code', ->
    h2 "Code"
    script type: 'syntaxhighlighter', class: 'brush: js',->
      '<![CDATA[
        /**
         * SyntaxHighlighter\n
         */
    function foo()
    {
        if (counter <= 10)
            return;
        // it works!
    }
  ]]>'
  
  div id: 'toolbar', ->
    form id: 'chat_form', ->
      input id: 'chat_box'
      input id: 'name', type: 'hidden', value: @name
      button id: 'say', -> 'Say'

    form id: 'code_form', ->
      input id: 'code_box'
      input id: 'name', type: 'hidden', value: @name
      button id: 'paste', -> 'Paste'

view login: ->
  @title = 'PATchat Login'
  h1 @title
  div id: 'login'
  form method: 'post', action: '/login', ->
    input id: 'name', name: 'name'
    button id: 'login', -> 'Login'

