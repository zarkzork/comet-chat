/* message is representation of the event to be shown on the message board */
/* from may be null, in such case message will be treated as error */
/* types of message: typer, message, error */
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
	  .text(this.from)
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
  /* queue of messages to be send over network */
  this.message_queue=[];
  /* true if request is being sent */
  this.request_processing=false;
  /* number of errors already accured while processing message */
  this.errors_occured=0;
  this.topic=new Topic("tst");
  this.messages=new Messages();
  this.mates=new Mates([]);
  this.makeInputBox(function(value, isFinal){
		      self.postMessage(value, isFinal);
		      if(isFinal){
			self.clearInputBox();
		      }
		    });
  this.topic.onChange=
    function(value, isFinal){
      console&&console.log(value+":"+isFinal);
    };
  $(window).unload(function(){self.leave();});
  this.enter(name,
	     function(){
	       self.getMates(
		 function(){
		   $("#connecting").hide();
		   $("#chat_section").show();
		   $("#input_line").focus();	
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
  scrollDownChat: function(){
    var height=$("#chat_section .chat_list *").height();
    $("#chat_section .chat_list").get(0).scrollTop=height;
  },
  /* enters to room and gets session id */
  enter: function(name, cb){
    var self=this;
    $.ajax({
	     type: "GET",
	     cache: false,
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
  leave: function(){
    $.ajax({
	     type: "GET",
	     cache: false,
	     url: "/json/"+this.room_id+"/leave",
	     data: "session="+this.session,
	     async: false
	   });
  },
  /* requests are processed one after another to not let the typer
   events come after real message, maybe there shoud be timeout for
   typer event */
  postMessage: function(text, isFinal){
    var self=this;
    var type= isFinal?"message":"typer";
    this.message_queue
      .push({ /* this property is needed just for postMessage() */
	      typer: true,
	      /* standart jquery ajax properties */
	      type: "GET",
	      cache: false,
	      url: "/json/"+this.room_id+"/"+type,
	      data: "session="+this.session+"&"+
		"message="+text,
	      dataType: "json",
	      success: function(data){
		if(data.result!='ok'){
		  self.showError("Can't send the message.");
		}
		self.messages.add(new Message(self.self,
					      text,
					      type));
		self.scrollDownChat();
		if(self.message_queue.length==0){
		  self.request_processing=false;
		}else{
		  self.processQueue();
		}
	      },
	      error: function(XMLHttpRequest,
			      textStatus,
			      errorThrown){
		console&&console.log("Can't send the message.");
		self.showError("Can't send the message. ("+
			       textStatus+")");
			if(self.message_queue.length==0){
		  self.request_processing=false;
		}else{
		  self.processQueue();
		}
	      }
	    });
    this.processQueue();    
  },
  processQueue: function(){
    if(!this.request_processing){
      this.request_processing=true;
      $.ajax(this.message_queue.shift());
      processQueue();
    }else{
      /* here we now that last element is unprocessed and if it */
      /* "typer" event we can remove it with new one. */
      if(this.message_queue.length>0 &&
	 this.message_queue[this.message_queue.length-1].typer){
	this.message_queue.pop();
      }
    }
  },
  getMates: function(cb){
    var self=this;
    $.ajax({
	     type: "GET",
	     cache: false,
	     url: "/json/"+this.room_id+"/mates",
	     data: "session="+this.session,
	     dataType: "json",
	     success: function(data){
	       if(data.result!='ok'){
		 self.showError("Can't load room mates.");
		 return;
	       }
	       for(var i in data.mates){
		 self.mates.add(data.mates[i]);
	       }
	       self.self=data.self_id;
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
	     url: "/json/"+this.room_id+"/get",
	     cache: false,
	     data: "session="+this.session,
	     dataType: "json",
	     success: function(data){
	       if(data.result=="timeout"){
		 continueProcessing();
		 return;
	       }
	       cb&&cb(data.event);
	       continueProcessing();
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.errors_occured++;
	       if(self.errors_occured>5){
		 self.showError('there was some error in getting'+
				'events from server');
	       }
	       setTimeout(continueProcessing, self.errors_occured*2000);
	     }
	   });
    function continueProcessing(){
      self.startProcessing(cb);
    }
  },
  process: function(event){
    var mate=null;
    switch(event.type){
    case "Message_event":
      mate=event.author;
      this.messages.add(new Message(mate, event.message, "message"));
      break;
    case "Typer_event":
       mate=event.author;
      this.messages.add(new Message(mate, event.message, "typer"));
      break;
    case "Mate_event":
      switch(event.status){
      case "enter":
	this.mates.add(event.mate);
	break;
      case "left":
	this.mates.remove(event.mate);
	break;
      default:
	throw "unsoported Mate_event type.";
      }
      break;
    default:
      throw "unsoported Event type.";
    }
    this.scrollDownChat();
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
  remove: function(name){
    this.mates=$.grep(this.mates,
		      function(n, i){
			return n!=name;
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
    this._obj.append( $("<li/>").text(mate) );
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
      $("#"+"typer_"+message.from).remove();
      $("#chat").append(li.attr("id", message.id));
      break;
    case "typer":
      var old_typer=$("#"+"typer_"+message.from);
      li.attr("id", "typer_"+message.from);
      if(old_typer.length!=0){
	var prev=old_typer.prev();
	old_typer.after(li);
	old_typer.remove();
	setTimeout(
	  function(){
	    li.fadeOut("slow", function(){
			 li.remove();
		       });
		   }, 10000);
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
  var timeout=-1;
  $(id).keydown(
    function(e){
      var value=$(id).attr("value");
      if(e.which==13){
      	if(value!=""){
	  if(timeout!=-1){
	    clearTimeout(timeout);
	  }
	  cb&&cb(value, true);
	}
      }
    });
  $(id).keyup(
    function(e){
      var value=$(id).attr("value");
      if(value!=""){
	if(timeout!=-1){
	  clearTimeout(timeout);
	}
	if(e.which!=13){
	  if(value.length%5==0){
	    cb&&cb(value, false);
	  }else{
	    timeout=setTimeout(
	      function(){
		cb&&cb(value, false);
	      }, 200);
	  }
	}
      }
    });
  $(id).change(
    function(){
      var value=$(id).attr("value");
      if(value!=""){
	cb&&cb(value, true);
      }
    });
}

$(function(){
    $("#enter_section form").submit(
      function(){
	$("#enter_section").hide();
	$("#connecting").show();
	new Room(document.location.hash.slice(1),
		 $("#mate_name").attr("value"));
	return false;
      });
    $("#mate_name").focus();
  });
