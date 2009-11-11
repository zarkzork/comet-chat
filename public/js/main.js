/* mate is object thar represents one of the room participants */
function Mate(id, name){
  this.id=id;
  this.name=name;
  return this;
}

/* message is representation of the event to be shown on the message board */
/* from may be null, in such case message will be treated as error */
/* types of message: typing, message, error */
function Message(from, text, type){
  this.from=from;
  this.text=text;
  this.type=type;
  this.id=name+text+type+Math.floor(Math.random()*100000);//dummy
  return this;
}

Message.prototype={
  /* returns li that will be inserted in proper place of the message board */
  getLi: function(){
    var li=$("<li/>")
      .addClass("message");
    if(this.from&&
       this.from!=null&&
       this.type!="error"){
      li.append(
	$("<span/>")
	  .addClass("from")
	  .text(this.from.name)
      );
    }
    li.append(
      $("<span/>")
	.addClass("message_body")
	.text(this.text)
    );
    return li;
  }
};

/* main object that represents room */
function Room(id, name){
  var self=this;
  this.room_id=id;
  /* that very man who is about to enter this room */
  this.self=null;
  /* session keeps session id that is needed in every network operation */
  this.session=null;
  this.topic=new Topic("tst");
  this.messages=new Messages();
  this.mates=new Mates([]);
  this.makeInputBox(function(value, isFinal){
		      if(isFinal){
			self.clearInputBox();
			self.postMessage(value);
		      }
		      if(console){
			console.log(value+":"+isFinal);
		      }
		    });
  this.topic.onChange=
    function(value, isFinal){
      if(console){
	console.log(value+":"+isFinal);
      }
    };
  this.enter(name,
	     function(){
	       self.getMates(
		 function(){
		   self.startProcessing(
		     function(event){
		       self.process(event);
		     }
		   );
		 }
	       );
	     });
}

Room.prototype={
  /* enters to room and gets session id */
  enter: function(name, cb){
    var self=this;
    $.ajax({
	     type: "GET",
	     url: "/json/"+this.room_id+"/enter",
	     data: "name="+name,
	     dataType: "json",
	     success: function(data){
	       if(data.result!='ok'){
		 self.showError("Can't enter the room.");
		 return;
	       }
	       self.session=data.session;
	       cb&&cb();
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.showError("Can't enter the room. ("+textStatus+")");
	     }
	   });
  },
  postMessage: function(text){
    this.messages.add(new Message(this.self, text, "message"));
    $.ajax({
	     type: "GET",
	     url: "/json/message",
	     data: "session="+this.session+"&"+
	       "message="+text,
	     dataType: "json",
	     success: function(data){
	       if(data.result!='ok'){
		 self.showError("Can't send the message.");
	       }
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.showError("Can't send the message. ("+textStatus+")");
	     }
	   });
  },
  getMates: function(cb){
    var self=this;
    $.ajax({
	     type: "GET",
	     url: "/json/mates",
	     data: "session="+this.session,
	     dataType: "json",
	     success: function(data){
	       if(data.result!='ok'){
		 self.showError("Can't load room mates.");
		 return;
	       }
	       for(var i in data.mates){
		 self.mates.add(new Mate(data.mates[i].id,
					 data.mates[i].name));
	       }
	       self.self=self.mates.get(data.self_id);
	       cb&&cb();
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.showError("Can't load room mates. ("+textStatus+")");
	     }
	   });
  },
  startProcessing: function(cb){
    var self=this;
    $.ajax({
	     type: "GET",
	     url: "/json/get",
	     data: "session="+this.session,
	     dataType: "json",
	     success: function(data){
	       if(data.result=="timeout"){
		 self.startProcessing(cb);
		 return;
	       }
	       cb&&cb(data.event);
	       self.startProcessing(cb);
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.startProcessing(cb);
	     }
	   });
  },
  process: function(event){
    switch(event.type){
    case "Message_event":
      var mate=this.mates.get(event.author);
      this.messages.add(new Message(mate, event.message, "message"));
      break;
    case "Mate_event":
      switch(event.status){
      case "enter":
	var new_mate=new Mate(event.mate.id,
			  event.mate.name);
	this.mates.add(new_mate);
	break;
      default:
	throw "unsoported Mate_event type.";
      }
      break;
    default:
      throw "unsoported Event type.";
    }
  },
  showError: function(text){
    var message=
      new Message(null, text, "error");
    this.messages.add(message);
  },
  clearInputBox: function(){
    $("#input_line").attr("value","");
  },
  makeInputBox: function(cb){
    typer("#input_line", cb);
    $("#send_button").click(
      function(){
	cb($("#input_line").attr("value"), true);
      });
    return this;
  }  
};

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
  get:function(id){
    return $.grep(this.mates,
	   function(n, i){
	     return n.id==id;
	   })[0];
  },
  remove: function(id){
    this.mates=$.grep(this.mates,
		      function(n, i){
			return n.id!=id;
		      });
    this.draw();
  },
  draw:function(){
    this._obj.empty();
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
    var li=message.getLi();
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
    case "error":
      $("#errors").append(li.attr("id", message.id));
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
	if(value!=""&&value!=value_send){
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
      if(value!=""&&value!=value_send){
	cb&&cb(value, true);
	value_send=value;
      }
    });
}

$(function(){
    
    new Room(document.location.hash.slice(1),
		      "dummy"+Math.floor(Math.random()*100));
  });
