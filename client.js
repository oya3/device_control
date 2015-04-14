// coding: utf-8
$(function() {
    var ws = new WebSocket("ws://172.17.10.58:3001");
    // メッセージ受信時の処理
    ws.onmessage = function(event){
        var message_li = document.createElement("li");
        message_li.textContent = event.data;
        document.getElementById("message_area").appendChild(message_li);
    };
    // メッセージ送信時の処理
    document.getElementById("read").onclick = function(){
        // var comment = document.getElementById("comment").value;
        // document.getElementById("comment").value = '';
        ws.send("read");
    };
});
