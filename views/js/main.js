function Mate(name){
  this.id=name+Math.floor(Math.random()*100000);//dummy
  this.name=name;
  return this;
}

/* types of message: typing, message */
function Message(from, text, type){
  this.from=from;
  this.text=text;
  this.type=type;
  this.id=name+text+type+Math.floor(Math.random()*100000);//dummy
  return this;
}

function Room(){
  this.topic=new Topic("tst");
  this.topic.onChange=
    function(value, isFinal){
	      if(console){
		console.log(value+":"+isFinal);
	      }
    };
  this.mates=new Mates([new Mate("zarkzork"),
			new Mate("wewiorka")]);
  this.messages=new Messages();
  /* test messages */
  this.messages.add(new Message(this.mates.mates[0],"tst","message"));
  this.messages.add(new Message(this.mates.mates[1],"ack tst","message"));
}

function Topic(text){
  var self=this;
  this.topic=text;
  this._obj=$("#topic");
  this.change(text);
  this.onChange=null;
  typer("#topic", function(value, isFinal){
	  self.onChange&&self.onChange(value, isFinal);
	});
  return this;
}

Topic.prototype={
  change: function(text){
    this._obj.attr("value", text);
  }
};

function Mates(mates){
  this.mates=mates;
  this._obj=$("#mates ul");
  this.draw();
  return this;
}

Mates.prototype={
  add: function(mate){
    this.mates.push(mate);
    this.draw();
  },
  remove: function(id){
    this.mates=$.grep(this.mates,
		      function(n, i){
			return n.id!=id;
		      });
    this.draw();
  },
  draw:function(){
    for(var i in this.mates){
      this._drawMate(this.mates[i]);
    }
  },
  _drawMate:function(mate){
    this._obj.append( $("<li/>").text(mate.name) );
  }
};

function Messages(){
  return this;
}

Messages.prototype={
  add:function(message){
    var li=$("<li/>")
      .addClass("message")
      .append(
	$("<span/>")
	  .addClass("from")
	  .text(message.from.name)
      )
      .append(
	$("<span/>")
	  .addClass("message_body")
	  .text(message.text)
      );
    switch(message.type){
    case "message":
      $("#chat").append(li.attr("id", message.id));
      break;
    case "typer":
      var old_typer=$("#"+"typer_"+message.from.id);
      li.attr("id", "typer_"+message.from.id);
      if(old_typer.length!=0){
	var prev=old_typer.prev();
	old_typer.after(li);
	old_typer.remove();
      }else{
	$("#typers").append(li);
      }
      break;
    default:
      throw "Illigal message type";
    }
  }
};

/* @cb(value, isFinal) is called when on object with selector
 @id onKeypress event. isFinal is false if last key is
 not enter*/
function typer(id, cb){
  var value_send=$(id).attr("value");
  var timeout=-1;
  
  $(id).keyup(
    function(e){
      var value=$(id).attr("value");
      if(timeout!=-1){
	clearTimeout(timeout);
      }
      if(e.which==13){
	if(value!=value_send){
	  cb&&cb(value, true);
	  value_send=value;
	}
      }else{
	if(value.length%5==0){
	  cb&&cb(value, false);
	}else{
	  timeout=setTimeout(
	    function(){
	      cb&&cb(value, false);
	    }, 1000);
	}
      }
    });
  $(id).change(
    function(){
      var value=$(id).attr("value");
      if(value!=value_send){
	cb&&cb(value, true);
	value_send=value;
      }
    });
}

$(function(){Room();});
