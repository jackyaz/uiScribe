String.prototype.lastIndexEnd = function(string) {
	if (!string) return -1;
	var io = this.lastIndexOf(string)
	return io == -1 ? -1 : io + string.length;
};

var lastLine = "";
var syslogWorker = new Worker("/user/logng_worker.js");

syslogWorker.onmessage = function(e) {
	if (!e.data.idx) return;
	var row = document.getElementById("syslogTable").rows[e.data.idx];
	
	cell = row.insertCell(-1);
	if (e.data.time) {
		cell.innerText = e.data.time.toString();
		cell.setAttribute("title", e.data.time.toString());
	}
	
	cell = row.insertCell(-1);
	if (e.data.host) cell.innerText = e.data.host;
	
	cell = row.insertCell(-1);
	if (e.data.severity) {
		cell.innerText = e.data.severity;
		cell.setAttribute("title", e.data.severity);
	}
	
	cell = row.insertCell(-1);
	if (e.data.header) {
		cell.innerText = e.data.header;
		cell.setAttribute("title", e.data.header);
	}
	
	cell = row.insertCell(-1);
	if (e.data.message) cell.innerText = e.data.message;
	
	if(e.data.time && e.data.header && e.data.message) row.classList.add("lvl_" + (e.data.severity || "unknown"));
}

function processLogFile(file) {
	var tbody = document.getElementById("syslogTable").getElementsByTagName("tbody")[0];
	var added = 0;
	file.substring(file.lastIndexEnd(lastLine)).split("\n").forEach(line => {
		if (line) {
			lastLine = "\n" + line + "\n";
			var row = tbody.insertRow(-1);
			var cell = row.insertCell(-1);
			cell.innerText = line;
			cell.colSpan = 5;
			syslogWorker.postMessage({idx: row.rowIndex, msg: line});
			added++;
		}
	});
	return added;
}

// Debug means no filter, so no need to include
var filterList = ['emerg','alert','crit','err','warning','notice','info'];

function filterSeverity(selectObject) {
	var container = document.getElementById("syslogContainer");
	var rescroll = (container.scrollHeight - container.scrollTop - container.clientHeight <= 1);
	var table = document.getElementById("syslogTable");
	for (const severity of filterList) {
		table.classList.toggle("filter_" + severity, selectObject.value == severity);
	}
	if(rescroll && !(container.scrollHeight - container.scrollTop - container.clientHeight <= 1)) $(container).animate({ scrollTop: container.scrollHeight - container.clientHeight }, "slow");
}

function initSeverity() {
	if(0 < <% nvram_get("log_level"); %> && <% nvram_get("log_level"); %> < 8) {
		document.getElementById("syslogTable").classList.add("filter_" + filterList[<% nvram_get("log_level"); %> - 1])
	}
}
