var command = "-"; // Global variable
var client_messages = 0;

function getRedisCommand(s) {
    if ( !s.fromUpstream ) {
        client_messages++;
        if ( client_messages == 1 ) { // Redis method appears in 3rd client packet
            var query_text = s.buffer.substr(1,20).toUpperCase();
            var commands = ["GET", "SET", "APPEND", "INFO"];
            var i = 0;
	    s.log("Query text: " + query_text);
            for (; i < commands.length; i++ ) {
                if ( query_text.search(commands[i]) > 0 ) {
                    s.log("Redis method: " + commands[i]); // To error_log [info]
                    command = commands[i];
                   return s.OK; // Stop searching
                }
            }
        }
    }
    return s.OK;
}

function setRedisCommand() {
    return command;
}
