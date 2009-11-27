(function(){
   var image=new Image();
   var draw_line=true;
   var canvas = document.getElementById('logo');  
   image.src="img/comet.jpg";
   image.onload=function(){
     if(canvas.getContext){
       setInterval(drawLogo, 600);
     }
   };

   function drawLogo(){
     var ctx = canvas.getContext('2d');
     var text=draw_line?"zZchat|":"zZchat";
     draw_line=!draw_line;
     ctx.save();
     ctx.clearRect(0, 0, 300, 300);
     ctx.fillStyle = "rgb(200,0,0)";  
     ctx.drawImage(image,0,0);
     ctx.globalCompositeOperation="destination-in";
     ctx.font="70px Georgia, sans-serif";
     ctx.fillText(text, 0, 60);
     ctx.restore();
   };
 })();