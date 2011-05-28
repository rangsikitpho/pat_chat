get '/': -> 
  @name = cookies['name']
  @names = all_names()
  @said_history = app.said_history || ''
  @coded_history = app.coded_history || ''
  if @name
    render 'index'
  else
    redirect '/login'

post '/login': -> 
  puts "Setting name cookie to " + params.name
  app.latest_name = params.name
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
  puts "Connected: #{id}: #{app.latest_name}"
  broadcast 'connected', id: id, name: 'blank connection', names: app.names

at disconnection: ->
  puts "Disconnected: #{id}"
  untrack_name(id)
  names = all_names()
  broadcast 'chatters_changed', id: id, names: names

msg said: ->
  puts "#{id}, #{@name} said: #{@text}"
  app.said_history ?= ''
  app.said_history += ("<p>#{@name}: #{@text}</p>")
  send 'said', id: id, name: @name, text: @text
  broadcast 'said', id: id, name: @name, text: @text

msg coded: ->
  puts "#{id}, #{@name} coded: #{@text}"
  @text = decorate_code(@text)
  app.coded_history ?= ''
  app.coded_history += ("<fieldset><legend>#{@name}</legend>#{@text}</fieldset>")
  puts "updated to #{@text}"
  send 'coded', id: id, name: @name, text: @text
  broadcast 'coded', id: id, name: @name, text: @text

msg logged_in: ->
  track_name(id,@name)
  names = all_names()
  puts "All names = #{names}"
  #send 'logged_in', id: id, name: @name
  broadcast 'logged_in', id: id, name: @name
  send 'chatters_changed', id: id, names: names
  broadcast 'chatters_changed', id: id, names: names

helper track_name: (connection_id,name) ->
  app.names ?= {}
  app.names[connection_id] = name

helper untrack_name: (connection_id) ->
  delete app.names[connection_id] if app.names

helper all_names: ->
  name for connection_id,name of app.names

def decorate_code: (code) ->
  "<pre class='prettyprint'>#{code.replace(/</g,"&lt;").replace(/>/g,"&gt;")}</pre>"

client index: ->
  $(document).ready ->
    SyntaxHighlighter.all()
    socket = new io.Socket()

    #socket.on 'connect', -> $('#chat').append '<p>Connected</p>'
    #socket.on 'disconnect', -> $('#chat').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected
        #$('#chat').append "<p>#{msg.connected.names[msg.connected.names.length-1]} Connected</p>"
      else if msg.said
        $('#chat').append "<p>#{msg.said.name}: #{msg.said.text}</p>"
        $("#chat").attr({ scrollTop: $("#chat").attr("scrollHeight") }) # Automaticall scroll to end of div
      else if msg.coded
        $('#code').append "<fieldset><legend>#{msg.coded.name}</legend>#{msg.coded.text}</fieldset>"
        $("#code").attr({ scrollTop: $("#code").attr("scrollHeight") }) # Automaticall scroll to end of div
        prettyPrint()
      else if msg.logged_in
        $('#chat').append "<p>#{msg.logged_in.name} logged in </p>"
      else if msg.chatters_changed
        $('#chatters').html "<p>Now Chatting: #{msg.chatters_changed.names.join(",")}</p>"


    $('#chat_form').submit ->
      socket.send JSON.stringify said: {text: $('#chat_box').val(), name: $('#name').val()}
      $('#chat_box').val('').focus()
      false

    $('#code_form').submit ->
      socket.send JSON.stringify coded: {text: $('#code_box').val(), name: $('#name').val()}
      $('#code_box').val('').focus()
      false

    socket.connect()

    # Scroll and prettyprint on load for history
    $("#chat").attr({ scrollTop: $("#chat").attr("scrollHeight") }) # Automaticall scroll to end of div
    $("#code").attr({ scrollTop: $("#code").attr("scrollHeight") }) # Automaticall scroll to end of div
    prettyPrint()

    socket.send JSON.stringify logged_in: { name: $('#name').val() }
    $('#chat_box').focus()

view index: ->
  @title = 'PATchat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/index', '/javascripts/shCore', '/javascripts/prettify']
  link rel: 'stylesheet', href: '/stylesheets/prettify.css'
  link rel: 'stylesheet', href: '/stylesheets/style.css'

  div id: 'title', ->
    h1 ->
      label "#{@title} "
      a href: '/logout', -> '(Logout)'

  div id: 'chatters', ->
    p "#{@names}"

  div id: 'chat', "#{@said_history}"

  div id: 'code', "#{@coded_history}"
  
  div id: 'toolbar', ->
    form id: 'chat_form', ->
      label "#{@name}: "
      input id: 'chat_box'
      input id: 'name', type: 'hidden', value: @name
      button id: 'say', -> 'Say'

    form id: 'code_form', ->
      textarea id: 'code_box'
      input id: 'name', type: 'hidden', value: @name
      button id: 'paste', -> 'Paste Code'

view login: ->
  link rel: 'stylesheet', href: '/stylesheets/style.css'
  @title = 'PATchat Login'
  div id: 'title', ->
    h1 @title
    div id: 'login'
    form method: 'post', action: '/login', ->
      input id: 'name', name: 'name'
      button id: 'login', -> 'Login'

