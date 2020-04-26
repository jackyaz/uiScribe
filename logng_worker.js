/*
 *  Bastardised from GlossyParser(Copyright Squeeks <privacymyass@gmail.com>)
 *
 *  Parses syslog-ng messages in the format:
 *    ${S_DATE} ${HOST} ${PRIORITY} ${MSGHDR}${MSG}
 *
 */

var LoggyParser = function() {};

/*
 *  Parse the raw message received.
 *
 *  @param {String/Buffer} rawMessage Raw message received from socket
 *  @param {Function} callback Callback to run after parse is complete
 *  @return {Object} map containing all successfully parsed data:
 *    originalMessage
 *    time
 *    host
 *    severity
 *    header
 *    message
 */
LoggyParser.prototype.parse = function(rawMessage, callback) {
	if(typeof rawMessage != 'string') {
		return rawMessage;
	}

	// Always return the original message
	var parsedMessage = {
		originalMessage: rawMessage
	};

	// The bit of the message that isn't the other bits of the message
	var rightMessage = rawMessage;

	// Date
	segment = rightMessage.match(/^(\d{4}\s+)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+/);
	parsedMessage.time = segment[0];
	rightMessage = rightMessage.substring(segment[0].length);

	var remainingMessage=rightMessage.split(' ');
	
	parsedMessage.host = remainingMessage[0];
	remainingMessage.shift();
	parsedMessage.severity = remainingMessage[0];
	remainingMessage.shift();
	parsedMessage.header = remainingMessage[0];
	remainingMessage.shift();
	
	
	// Whatever is left
	parsedMessage.message = remainingMessage.join(' ');
	console.log(parsedMessage);
	if(callback) {
		callback(parsedMessage);
	} else {
		return parsedMessage;
	}
};

var syslogParser = new LoggyParser();
onmessage = function(e) {
	syslogParser.parse(e.data.msg, (msg) => {
		msg.idx = e.data.idx;
		postMessage(msg);
	});
}
