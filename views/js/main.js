function Room(){
  this.topic=new Topic();
  this.mates=new Mates();
  this.messages=new Messages();
}

function Topic(){
  this._obj=$("#topic");
  return this;
}

Topic.prototype={
  change: function(text){
    this._obj.text(text);
  }
};


function Mates(){
  return this;
}

Mates.prototype={
  draw:function(){
  }
};

function Messages(){
  return this;
}

Messages.prototype={
  add:function(){
  }
};