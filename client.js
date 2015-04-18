// coding: utf-8
jQuery(function ($) {
// $(function() {
    var ws = null;
    // 接続
    function open() {
        if (ws == null) {
            // WebSocket の初期化
            address = $('input.pasori-address').val();
            // TODO: address のフォーマットチェックが必要...
            ws = new WebSocket("ws://" + address);
            // イベントハンドラの設定
            ws.onopen = onOpen;
            ws.onmessage = onMessage;
            ws.onclose = onClose;
            ws.onerror = onError;
            $("label.status").text("接続中...");
        }
    }
    
    function onOpen(event) {
        console.log("接続した");
        $("label.status").text("接続");
    }
    function onClose(event) {
        console.log("切断した");
        $("label.status").text("切断");
        ws = null;
    }
    function onError(event) {
        console.log("エラー発生");
        $("label.status").text("エラー発生");
        
        var message_li = document.createElement("li");
        message_li.textContent = "エラー発生"
        document.getElementById("message_area").appendChild(message_li);
    }
    
    function onMessage(event){
        console.log("メッセージ受信");
        var json = JSON.parse(event.data);
        var contents = json.contents;
        var history = contents.history;
        $('table.idm-ppm tbody').append('<th>' + contents.idm +'</th>');
        $('table.idm-ppm tbody').append('<th>' + contents.pmm +'</th>');
        var index = 0;
        var max = history.length;
        for(index = 0; index < max; index++){
            
            var line = '<th>' + history[index].ctype +'</th>';
            line += '<th>' + history[index].ctype_name +'</th>';
            line += '<th>' + history[index].proc + '</th>';
            line += '<th>' + history[index].proc_name + '</th>';
            line += '<th>' + history[index].date + '</th>';
            line += '<th>' + history[index].date_string + '</th>';
            line += '<th>' + history[index].time + '</th>';
            line += '<th>' + history[index].time_string + '</th>';
            line += '<th>' + history[index].balance + '</th>';
            line += '<th>' + history[index].region + '</th>';
            line += '<th>' + history[index].seq + '</th>';
            line += '<th>' + history[index].in_line + '</th>';
            line += '<th>' + history[index].in_sta + '</th>';
            line += '<th>' + history[index].out_line + '</th>';
            line += '<th>' + history[index].out_sta + '</th>';
            $('table.history tbody').append('<tr>'+ line + '</tr>');
        }
        
        // var message_li = document.createElement("li");
        // message_li.textContent = event.data;
        // document.getElementById("message_area").appendChild(message_li);
    }

    function clear(event){
        $('table.idm-ppm tbody *').remove();
        $('table.history tbody *').remove();
    }
    
    // メッセージ送信時の処理
    // document.getElementById("read").onclick = function(){
    $("input.read").click(function(){
        // var comment = document.getElementById("comment").value;
        // document.getElementById("comment").value = '';
        $(clear);
        ws.send("read");
    });
    
    // 接続
    $("input.connect").click( function(){
        $(open);
    });
    
    // 切断
    $("input.disconnect").click( function(){
        if (ws != null) {
            ws.close;
        }
    });
    
    // クリア
    //document.getElementById("clear").onclick = function(){
    $("input.clear").click(function(){
        $(clear);
        // $('table.idm-ppm tbody *').remove();
        // $('table.history tbody *').remove();
    });
    
    // $(open);
});
