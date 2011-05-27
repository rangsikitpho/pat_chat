(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  def({
    sleep: function(secs, cb) {
      return setTimeout(cb, secs * 1000);
    }
  });
  get({
    '/': function() {
      return redirect('/bar');
    },
    '/:foo': function() {
      this.foo += '?';
      return sleep(5, __bind(function() {
        this.foo += '!';
        this.title = 'Async';
        return render('default');
      }, this));
    }
  });
  view(function() {
    h1(this.title);
    return p(this.foo);
  });
}).call(this);
