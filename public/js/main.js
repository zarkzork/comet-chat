/* message is representation of the event to be shown on the message board */
/* from may be null, in such case message will be treated as error */
/* types of message: typer, message, error */
function Message(from, text, type){
  this.from=from;
  this.text=text;
  this.type=type;
  this.created_at=new Date();
  return this;
}

Message.prototype={
  /* returns li that will be inserted in proper place of the message board */
  getLi: function(){
    var self=this;
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
    li.hover(function(){
	       $(this).append($('<span/>')
			 .addClass('time')
			 .text(self.created_at.toLocaleTimeString()));
	     },
	     function(){
	       $(this).children('.time').remove();
	     });
    return li;
  }
};

/* main object that represents chat room */
function Room(id, name){
  this.room_id=id;
  this.name=name;
  /* person who about to enter this room */
  this.self=null;
  /* topic object to control topic representation */  
  this.topic=new Topic("");
  /* and mates */
  this.mates=new Mates([]);
  /* same for messages */
  this.messages=new Messages();
  /* true when user leaves pages open while visiting other pages. */
  this.hidden=false;
  /* number of message posted when window blurred */
  this.counter=0;
  this.network_controller=new NetworkController(this);
  this.controlsInit();
  this.networkInit();
}

Room.prototype={
  networkInit: function(){
    var self=this;
    /* leave room when winwow unloads */
    $(window).unload(function(){
  		       self.network_controller.leave();
  		     });
    /* enter the room and get its mates */
    this.network_controller.enter(this.name,
				  function(result){
				    switch(result){
				    case "duplicate":
				      gate.show("This name is taken. Take another try.");
				      self.unbind();
				      break;
				    case "error":
				      gate.show("Something bad happened. Lets try again!");
				      self.unbind();
				      break;
				    case "ok":
				      self.network_controller.getMates(
					function(){
					  $("#connecting").hide();
					  $("#chat_section").show();
					  $("#input_line").focus();	
					  self.network_controller.startProcessing(
					    function(event){
					      self.process(event);
					    }
					  );
					}
				      );
				      break;
				    default:
				      self.unbind();
				      alert("Something really bad happened. Reload window. I hope it helps.");
				    }
				  });    
  },

  controlsInit: function(){
    var self=this;
    this.makeInputBox(function(value, isFinal){
			var nc=self.network_controller;
			nc.postMessage(value, isFinal);
			if(isFinal){
			  self.clearInputBox();
			}
		      });
    this.topic.onChange=
      function(value, isFinal){
	var nc=self.network_controller;
	nc.topicChange(value);
      };
    this.mates.whenAlone(function(isAlone){
			   if(isAlone){
			     self.showHelp();
			   }else{
			     self.hideHelp();
			   }
			 });
    $(window).blur(function(){
		       self.hidden=true;
		     });
    $(window).focus(function(){
		      self.hidden=false;
		      self.removeCounter();  
		    });

  },

  unbind: function(){
    $.each(["#input_line","#topic","window"], function(key, val){
	     $(val).unbind();
	   });
  },
    
  scrollDownChat: function(){
    var height=$("#chat").height();
    height+=$("#typers").height();
    height+=$("#errors").height();
    $("#chat_section .chat_list").get(0).scrollTop=height;
  },

  process: function(event){
    var mate=null;
    switch(event.type){
    case "Message_event":
      mate=event.author;
      this.messages.add(new Message(mate, event.message, "message"));
      this.updateCounter();
      break;
    case "Typer_event":
      mate=event.author;
      this.messages.add(new Message(mate, event.message, "typer"));
      break;
    case "Topic_event":
      this.topic.change(event.message);
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
  
  showHelp: function(){
    $("#help").show();
  },
  
  hideHelp: function(){
    $("#help").hide();
  },
  
  clearInputBox: function(){
    $("#input_line").attr("value","");
  },
  
  makeInputBox: function(cb){
    typer("#input_line", cb);
    /* when user clicks the button, onedit event is already envoked */
    // $("#send_button").click(
    //   function(){
    // 	cb($("#input_line").attr("value"), true);
    //   });
    return this;
  },

  updateCounter: function(){
    if(this.hidden){
      this.counter++;
      document.title=document.title.replace(/(\[\d+\])?(.*)/,
					    '['+this.counter+']'+"$2");
    }
  },

  removeCounter: function(){
    this.counter=0;
    document.title=document.title.replace(/\[\d+\](.*)/,"$1");
  }
  
};

function testNetworkController(){
  var messages_posted=0;
  function getRoomName(){
    return "room"+Math.floor(Math.random()*1000);
  }
  function createTestRoom(){
    return {
      room_id:getRoomName(),
      mates:new Mates([]),
      messages:{add:
		function(){
		  messages_posted++;
		  console.log("message");
		}
	       },
      topic:{change:function(){;}},
      scrollDownChat: function(){;}
    };
  }
  function assert(statement, message){
    if(!statement){
      var err="assert failed "+(message||"");
      console.error(err);
      throw err;
    }
  }
  console.log("testing default use case");
  var nc=new NetworkController(createTestRoom());
  assert(nc.session==null);
  nc.enter("vasya",
	   function(){
	     assert(nc.session!=null);
	     console.log("logged in");
	     nc.startProcessing();
	     console.log("started processing");
	     nc.getMates(
	       function(){
		 assert(nc.room.mates.mates.length==1);
		 assert(nc.room.self=="vasya");
		 console.log("loaded mates");
		 nc.postMessage("tst",true);
		 nc.postMessage("tst2",true);
		 console.log("posted two messages");
		 setTimeout(function(){
			     assert(messages_posted==2);			     
			   }, 2000);
	       });
	   });
}


/* Part of room that handles all ajax messages.*/
function NetworkController(room){
  this.room=room;
  this.room_id=room.room_id;
  /* session keeps session id that is needed in every network operation */
  this.session=null;
  /* queue of messages to be send over network */
  this.message_queue=[];
  /* true if request is being sent */
  this.request_processing=false;
  /* number of errors already accured while processing message */
  this.errors_occured=0;
  return this;
}

NetworkController.prototype={
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
		 self.room.showError("Can't load room mates.");
		 return;
	       }
	       for(var i in data.mates){
		 self.room.mates.add(data.mates[i]);
	       }
	       self.room.self=data.self_id;
	       cb&&cb();
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.room.showError("Can't load room mates. ("+textStatus+")");
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
		 self.room.showError('there was some error in getting'+
				'events from server');
	       }
	       setTimeout(continueProcessing, self.errors_occured*2000);
	     }
	   });
    function continueProcessing(){
      self.startProcessing(cb);
    }
  },

  /* enters to room and gets session id */
  /* callback retuns result of room enter */
  enter: function(name, cb){
    var self=this;
    var escaped_name=encodeURIComponent(name);
    $.ajax({
	     type: "GET",
	     cache: false,
	     url: "/json/"+this.room_id+"/enter",
	     data: "name="+escaped_name,
	     dataType: "json",
	     success: function(data){
	       if(data.result==="ok"){
		 self.session=data.session;
		 self.room.topic.change(data.topic);		 
	       }
	       cb&&cb(data.result);
	     },
	     error: function(XMLHttpRequest, textStatus, errorThrown){
	       self.room.showError("Can't enter the room. ("+textStatus+")");
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


  /* function to generate request objects for jquery ajax requests for message, typer, and topic change */  
  _createAJAXMessage: function(type, text){
    var self=this;
    var escaped_text=encodeURIComponent(text);
    return {
      /* this property is needed just for processQueue() */
      typer: type=="typer",
      /* standart jquery ajax properties */
      type: "GET",
      cache: false,
      url: "/json/"+this.room_id+"/"+type,
      data: "session="+this.session+"&"+
	"message="+escaped_text,
      dataType: "json",
      success: function(data){
	if(data.result!='ok'){
	  self.room.showError("Can't send the message.");
	}
	switch(type){
	case "message":
	case "typer":
	  self.room.messages.add(new Message(self.room.self,
					     text,
					     type));
	  self.room.scrollDownChat();
	  break;
	case "topic":
	  break;
	default:
	  throw "unsopported type";
	}
	self.request_processing=false;
	self.processQueue();
      },
      error: function(XMLHttpRequest,
		      textStatus,
		      errorThrown){
	self.room.showError("Can't send the message. ("+
			    textStatus+","+errorThrown+")");
	self.request_processing=false;
	self.processQueue();
      }
    };
  },
  
  topicChange: function(topic){
    var self=this;
    this.message_queue
      .push(
	this._createAJAXMessage("topic", topic)
	    );
    this.processQueue();
  },

  /* requests are processed one after another to not let the typer
   events come after real message, maybe there shoud be timeout for
   typer event */
  postMessage: function(text, isFinal){
    var self=this;
    var type= isFinal?"message":"typer";
    this.message_queue
      .push(this._createAJAXMessage(type, text));
    this.processQueue();    
  },
  
  processQueue: function(){
    if((!this.request_processing)&&this.message_queue.length!=0){
      this.request_processing=true;
      $.ajax(this.message_queue.shift());
    }
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
  whenAlone: function(cb){
    this._onAlone=cb;
  },
  add: function(mate){
    this.mates.push(mate);
    this.draw();
    if(this._onAlone!==undefined){
      if(this.mates.length==1){
	this._onAlone(true);
      }else{
	this._onAlone(false);
      }
    }
    
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
    var encoded_from="";
    for (var i=0;i<message.from.length;i++){
      encoded_from+=message.from.charCodeAt(i);
    }
    switch(message.type){
    case "message":
      $("#"+"typer_"+encoded_from).remove();
      $("#chat").append(li);
      break;
    case "typer":
      var old_typer=$("#"+"typer_"+encoded_from);
      li.attr("id", "typer_"+encoded_from);
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

/* controls first screen. */
function Gate(){
  return this;
}

Gate.prototype={
  show:function(message){
    $("#enter_section .enter_message").text(message).show();
    $("#enter_section").show();
  },
  init:function(){
    var self=this;
    $("#enter_section form").submit(
      function(){
	$("#enter_section").hide();
	$("#connecting").show();
	new Room(document.location.pathname.slice(1),
		 $("#mate_name").attr("value"));
	return false;
      });
    $("#mate_name").focus();    
  }
};

var gate=new Gate();

$(function(){
    gate.init();
  });
