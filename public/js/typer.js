function error(message){
    message="Strange error occured"+message
    alert(message);
}

/* ROOM */
function Room(room_id){
    this.room_id=room_id;
    this.mates=null;
    this.session=null;
}

Room.prototype.enter=function(name, cb){
    room=this;
    $.getJSON("/json/"+this.room_id+"/enter?name="+name,
	      function(data){
		  if(data.result!='ok'){
		      error("Can't enter the room");
		      return;
		  }
		  room.session=data.session;
		  cb&&cb();
	      });
}

Room.prototype.postMessage=function(message){
    $.getJSON("/json/message?session="+this.session+"&"+
      "message="+message,
      function(data){
	  if(data.result!='ok'){
	      error("can't send message");
	  }
      });
}
	  

Room.prototype.getMates=function(cb){
    room=this;
    $.getJSON("/json/mates?session="+this.session,
	      function(data){
		  if(data.result!='ok'){
		      error("Can't get mates");
		      return;
		  }
		  room.mates=data.mates;
		  cb&&cb();
	      });
}

Room.prototype.getEvent=function(cb){
    room=this;
    $.ajax({
	type: "GET",
	url: "/json/get",
	data: "session="+this.session,
	dataType: "json",
	success: function(data){
	    if(data.result=="timeout"){
		room.getEvent(cb);
		return;
	    }
	    cb&&cb(data.event);
	},
	error: function(XMLHttpRequest, textStatus, errorThrown){
	    room.getEvent(cb);
	}
    });
}


/* TYPER */
function typer(id, cb){
    $(id).keypress(function(e){
	if(e.which==13){
	    cb($(this).attr("value"), true);
	    $(this).attr("value","");
	}
	if(e.which==32)
	    cb($(this).attr("value"), false);
    });
}
