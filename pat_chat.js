require('zappa').run(function(){get({
  '/': function() {
    this.name = cookies['name'] || '';
    this.names = all_names();
    this.said_history = app.said_history || '';
    this.coded_history = app.coded_history || '';
    this.port = 80;
    return render('index');
  }
});
post({
  '/login': function() {
    puts("Setting name cookie to " + params.name);
    app.latest_name = params.name;
    response.cookie('name', params.name, {
      expires: new Date(Date.now() + 3600 * 24 * 1000 * 360),
      path: "/"
    });
    return redirect('/');
  }
});
get({
  '/login': function() {
    puts('normal login');
    return render('login');
  }
});
get({
  '/logout': function() {
    response.clearCookie('name');
    return redirect('/');
  }
});
get({
  '/counter': function() {
    return "# of messages so far: " + app.counter;
  }
});
at({
  connection: function() {
    var _ref;
        if ((_ref = app.counter) != null) {
      _ref;
    } else {
      app.counter = 0;
    };
    puts("Connected: " + id + ": " + app.latest_name);
    return broadcast('connected', {
      id: id,
      name: 'blank connection',
      names: app.names
    });
  }
});
at({
  disconnection: function() {
    var names;
    puts("Disconnected: " + id);
    untrack_name(id);
    names = all_names();
    return broadcast('chatters_changed', {
      id: id,
      names: names
    });
  }
});
msg({
  said: function() {
    var _ref;
    puts("" + id + ", " + this.name + " said: " + this.text);
        if ((_ref = app.said_history) != null) {
      _ref;
    } else {
      app.said_history = '';
    };
    app.said_history += "<p>" + this.name + ": " + this.text + "</p>";
    send('said', {
      id: id,
      name: this.name,
      text: this.text
    });
    return broadcast('said', {
      id: id,
      name: this.name,
      text: this.text
    });
  }
});
msg({
  coded: function() {
    var _ref;
    puts("" + id + ", " + this.name + " coded: " + this.text);
    this.text = decorate_code(this.text);
        if ((_ref = app.coded_history) != null) {
      _ref;
    } else {
      app.coded_history = '';
    };
    app.coded_history += "<fieldset><legend>" + this.name + "</legend>" + this.text + "</fieldset>";
    puts("updated to " + this.text);
    send('coded', {
      id: id,
      name: this.name,
      text: this.text
    });
    return broadcast('coded', {
      id: id,
      name: this.name,
      text: this.text
    });
  }
});
msg({
  logged_in: function() {
    var names;
    track_name(id, this.name);
    names = all_names();
    puts("All names = " + names);
    broadcast('logged_in', {
      id: id,
      name: this.name
    });
    send('chatters_changed', {
      id: id,
      names: names
    });
    return broadcast('chatters_changed', {
      id: id,
      names: names
    });
  }
});
helper({
  track_name: function(connection_id, name) {
    var _ref;
        if ((_ref = app.names) != null) {
      _ref;
    } else {
      app.names = {};
    };
    return app.names[connection_id] = name;
  }
});
helper({
  untrack_name: function(connection_id) {
    if (app.names) {
      return delete app.names[connection_id];
    }
  }
});
helper({
  all_names: function() {
    var connection_id, name, _ref, _results;
    _ref = app.names;
    _results = [];
    for (connection_id in _ref) {
      name = _ref[connection_id];
      _results.push(name);
    }
    return _results;
  }
});
def({
  decorate_code: function(code) {
    return "<pre class='prettyprint'>" + (code.replace(/</g, "&lt;").replace(/>/g, "&gt;")) + "</pre>";
  }
});
client({
  index: function() {
    return $(document).ready(function() {
      var socket;
      SyntaxHighlighter.all();
      socket = new io.Socket();
      socket.on('message', function(raw_msg) {
        var msg;
        msg = JSON.parse(raw_msg);
        if (msg.connected) {
          ;
        } else if (msg.said) {
          $('#chat').append("<p>" + msg.said.name + ": " + msg.said.text + "</p>");
          return $("#chat").attr({
            scrollTop: $("#chat").attr("scrollHeight")
          });
        } else if (msg.coded) {
          $('#code').append("<fieldset><legend>" + msg.coded.name + "</legend>" + msg.coded.text + "</fieldset>");
          $("#code").attr({
            scrollTop: $("#code").attr("scrollHeight")
          });
          return prettyPrint();
        } else if (msg.logged_in) {
          return $('#chat').append("<p>" + msg.logged_in.name + " logged in </p>");
        } else if (msg.chatters_changed) {
          return $('#chatters').html("<p>Now Chatting: " + (msg.chatters_changed.names.join(",")) + "</p>");
        }
      });
      $('#chat_form').submit(function() {
        socket.send(JSON.stringify({
          said: {
            text: $('#chat_box').val(),
            name: $('#chat_form #name').val()
          }
        }));
        $('#chat_box').val('').focus();
        return false;
      });
      $('#code_form').submit(function() {
        socket.send(JSON.stringify({
          coded: {
            text: $('#code_box').val(),
            name: $('#code_form #name').val()
          }
        }));
        $('#code_box').val('').focus();
        return false;
      });
      socket.connect();
      $("#chat").attr({
        scrollTop: $("#chat").attr("scrollHeight")
      });
      $("#code").attr({
        scrollTop: $("#code").attr("scrollHeight")
      });
      prettyPrint();
      if ($('#chat_form #name').val() === '') {
        $("#login").dialog({
          modal: true,
          title: "Please Login",
          closeOnEscape: false,
          open: function(event, ui) {
            return $(".ui-dialog-titlebar-close").hide();
          },
          height: 120
        });
        return $('#login #name').focus();
      } else {
        socket.send(JSON.stringify({
          logged_in: {
            name: $('#chat_form #name').val()
          }
        }));
        return $('#chat_box').focus();
      }
    });
  }
});
view({
  index: function() {
    this.title = 'PATchat';
    this.scripts = ['/javascripts/jquery-1.5.1.min', '/socket.io/socket.io', '/index', '/javascripts/shCore', '/javascripts/prettify', '/javascripts/jquery-ui-1.8.13.custom.min'];
    link({
      rel: 'stylesheet',
      href: '/stylesheets/prettify.css'
    });
    link({
      rel: 'stylesheet',
      href: '/stylesheets/style.css'
    });
    link({
      rel: 'stylesheet',
      href: '/stylesheets/ui-darkness/jquery-ui-1.8.13.custom.css'
    });
    div({
      id: 'title'
    }, function() {
      return h1(function() {
        label("" + this.title + " ");
        return a({
          href: '/logout'
        }, function() {
          return '(Logout)';
        });
      });
    });
    div({
      id: 'chatters'
    }, function() {
      return p("" + this.names);
    });
    div({
      id: 'chat'
    }, "" + this.said_history);
    div({
      id: 'code'
    }, "" + this.coded_history);
    div({
      id: 'login'
    }, function() {
      return form({
        method: 'post',
        action: '/login'
      }, function() {
        input({
          id: 'name',
          name: 'name'
        });
        return button({
          id: 'login'
        }, function() {
          return 'Login';
        });
      });
    });
    return div({
      id: 'toolbar'
    }, function() {
      form({
        id: 'chat_form'
      }, function() {
        label("" + this.name + ": ");
        input({
          id: 'chat_box'
        });
        input({
          id: 'name',
          type: 'hidden',
          value: this.name
        });
        return button({
          id: 'say'
        }, function() {
          return 'Say';
        });
      });
      return form({
        id: 'code_form'
      }, function() {
        textarea({
          id: 'code_box'
        });
        input({
          id: 'name',
          type: 'hidden',
          value: this.name
        });
        return button({
          id: 'paste'
        }, function() {
          return 'Paste Code';
        });
      });
    });
  }
});
view({
  login: function() {
    link({
      rel: 'stylesheet',
      href: '/stylesheets/style.css'
    });
    this.title = 'PATchat Login';
    return div({
      id: 'title'
    }, function() {
      h1(this.title);
      div({
        id: 'login'
      });
      return form({
        method: 'post',
        action: '/login'
      }, function() {
        input({
          id: 'name',
          name: 'name'
        });
        return button({
          id: 'login'
        }, function() {
          return 'Login';
        });
      });
    });
  }
});}, { 'port': ['80'] });
