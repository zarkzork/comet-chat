$(document).ready(function(){
    var room=new Room($("#room_hexdigest").attr("value"));
    $(".name_box").submit(function(){
	enterChatroom(room);
	return false;
    });
    $("#loading").hide();
    $("#room_enter").show();

    function enterChatroom(){
	var name=$("#name_input_box").attr("value");
	room.enter(name, function(){
	    $("#room_enter").hide();
	    typer("#chat_input", function(message, isFinal){
		if(isFinal)room.postMessage(message);
	    });
	    room.getMates(function(){
		for(var i in room.mates){
		    var li=$("<li>").text(room.mates[i].name);
		    $("#mates").append(li);
		}
		$("#room").show();
		eventLoop(room);
	    });
	});
    }

    function eventLoop(){
	room.getEvent(function(event){
	    eventProcessor(event);
	    eventLoop();
	});
    }

    /* EVENT PROCESSING */
    function eventProcessor(event){
	switch(event.type){
	case "Message_event": processMessage(event);break;
	default: error("uknown message type");
	}
    }

    function processMessage(message){
	var author=$("<span>").text(message.author+": ");
	var text=$("<span>").text(message.message);
	var li=$("<li>").append(author).append(text);
	$("#chat ol").append(li);
	var chat_box=document.getElementById("chat");
	chat_box.scrollTop = chat_box.scrollHeight;
    }
    
});

