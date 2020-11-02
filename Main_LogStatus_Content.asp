<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>System Log - enhanced by Scribe</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
  font-weight: bolder;
}

thead.collapsible-jquery {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

.btndisabled {
  border: 1px solid #999999 !important;
  background-color: #cccccc !important;
  color: #000000 !important;
  background: #cccccc !important;
  text-shadow: none !important;
  cursor: default !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script>
var timeouts = [];

function showclock(){
	JS_timeObj.setTime(systime_millsec);
	systime_millsec += 1000;
	JS_timeObj2 = JS_timeObj.toString();
	JS_timeObj2 = JS_timeObj2.substring(0,3) + ", " +
	JS_timeObj2.substring(4,10) + " " +
	checkTime(JS_timeObj.getHours()) + ":" +
	checkTime(JS_timeObj.getMinutes()) + ":" +
	checkTime(JS_timeObj.getSeconds()) + " " +
	/*JS_timeObj.getFullYear() + " GMT" +
	timezone;*/ // Viz remove GMT timezone 2011.08
	JS_timeObj.getFullYear();
	document.getElementById("system_time").value = JS_timeObj2;
	setTimeout(showclock, 1000);
	if(navigator.appName.indexOf("Microsoft") >= 0)
	document.getElementById("log_messages").style.width = "99%";
}

function showbootTime(){
	Days = Math.floor(boottime / (60*60*24));
	Hours = Math.floor((boottime / 3600) % 24);
	Minutes = Math.floor(boottime % 3600 / 60);
	Seconds = Math.floor(boottime % 60);
	document.getElementById("boot_days").innerHTML = Days;
	document.getElementById("boot_hours").innerHTML = Hours;
	document.getElementById("boot_minutes").innerHTML = Minutes;
	document.getElementById("boot_seconds").innerHTML = Seconds;
	boottime += 1;
	setTimeout(showbootTime, 1000);
}

function clearLog(){
	document.form1.target = "hidden_frame";
	document.form1.action_mode.value = " Clear ";
	document.form1.submit();
	location.href = location.href;
}

function showDST(){
	var system_timezone_dut = "<% nvram_get("time_zone"); %>";
	if(system_timezone_dut.search("DST") >= 0 && "<% nvram_get("time_zone_dst"); %>" == "1"){
	document.getElementById('dstzone').style.display = "";
	document.getElementById('dstzone').innerHTML = "* Daylight savings time is enabled in this time zone.";
	}
}

function capitalise(string){
	return string.charAt(0).toUpperCase() + string.slice(1);
}

function initial(){
	show_menu();
	showclock();
	showbootTime();
	showDST();
	get_conf_file();
}

function applySettings(){
	document.config_form.submit();
}

var logfilelist="";
function get_all_logfiles(){
	timeouts.push(setTimeout(function(){get_logfile('messages');},Math.round(Math.random() * 3000)));
	eval(logfilelist);
	if(document.getElementById("auto_refresh").checked){
		timeouts.push(setTimeout(get_all_logfiles, 5000));
	}
}

function get_logfile(filename){
	$.ajax({
		url: '/ext/uiScribe/'+filename+'.htm',
		dataType: 'text',
		error: function(xhr){
			timeouts.push(setTimeout(function(){get_logfile(filename);}, 3000));
		},
		success: function(data){
			if(document.getElementById("auto_refresh").checked){
				if(filename!="messages"){
					document.getElementById("log_"+filename.substring(0,filename.indexOf("."))).innerHTML = data;
					if (document.getElementById("auto_scroll").checked){
						$("#log_"+filename.substring(0,filename.indexOf("."))).animate({ scrollTop: 9999999 }, "slow");
					}
				} else{
					document.getElementById("log_"+filename).innerHTML = data;
					if (document.getElementById("auto_scroll").checked){
						$("#log_"+filename).animate({ scrollTop: 9999999 }, "slow");
					}
				}
			}
		}
	});
}

function get_conf_file(){
	$.ajax({
		url: '/ext/uiScribe/logs.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_conf_file, 1000);
		},
		success: function(data){
			var logs=data.split("\n");
			logs.sort();
			logs.reverse();
			logs=logs.filter(Boolean);
			logfilelist="";
			for (var i = 0; i < logs.length; i++){
				var commentstart=logs[i].indexOf("#");
				if (commentstart != -1){
					continue
				}
				var filename=logs[i].substring(logs[i].lastIndexOf("/")+1);
				$("#table_messages").after(BuildLogTable(filename));
				logfilelist+='timeouts.push(setTimeout(function(){get_logfile("'+filename+'");},Math.round(Math.random() * 3000)));';
			}
			AddEventHandlers();
			get_all_logfiles();
		}
	});
}

function DownloadAllLogFile(){
	$(".btndownload").each(function(index){$(this).trigger("click");});
}

function DownloadLogFile(btnlog){
	$(btnlog).prop('disabled', true);
	$(btnlog).addClass("btndisabled");
	var filepath = "";
	if(btnlog.name == "btnmessages"){
		filepath='/ext/uiScribe/messages.htm'
	}
	else{
		filepath='/ext/uiScribe/'+btnlog.name.replace("btn","")+'.log.htm'
	}
	fetch(filepath).then(resp => resp.blob()).then(blob => {
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.style.display = 'none';
		a.href = url;
		a.download = btnlog.name.replace("btn","")+'.log';
		document.body.appendChild(a);
		a.click();
		window.URL.revokeObjectURL(url);
		$(btnlog).prop('disabled', false);
		$(btnlog).removeClass("btndisabled");
	})
	.catch(() => {
		console.log('File download failed!');
		$(btnlog).prop('disabled', false);
		$(btnlog).removeClass("btndisabled");
	});
}

function BuildLogTable(name){
	var loghtml='<div style="line-height:10px;">&nbsp;</div>';
	loghtml+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_'+name.substring(0,name.indexOf("."))+'">';
	loghtml+='<thead class="collapsible-jquery"><tr><td colspan="2">'+name+' (click to show/hide)</td></tr></thead>';
	loghtml+='<tr><td style="padding: 0px;">';
	loghtml+='<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_'+name.substring(0,name.indexOf("."))+'" class="textarea_log_table" style="font-family:\'Courier New\', Courier, mono; font-size:11px;">Log goes here</textarea>';
	loghtml+='</td></tr>';
	loghtml+='<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77, 89, 93);border:0px;">';
	loghtml+='<input type="button" onclick="DownloadLogFile(this)" value="Download log file" class="button_gen btndownload" name="btn'+name.substring(0,name.indexOf("."))+'" id="btn'+name.substring(0,name.indexOf("."))+'">';
	loghtml+='</td></tr>';
	loghtml+='</table>';
	return loghtml;
}

function AddEventHandlers(){
	$(".collapsible-jquery").click(function(){
		$(this).siblings().toggle("slow");
	});
	
	ResizeAll("hide");
	
	$("#auto_refresh")[0].addEventListener("click", function(){ToggleRefresh();});
	$("#auto_refresh")[0].addEventListener("click", function(){ToggleScroll();});
}

function ToggleRefresh(){
	$("#auto_scroll").prop('disabled', function(i, v){ if(v){get_all_logfiles();} else{ClearAllTimeouts();} });
}

function ToggleScroll(){
	$("#auto_scroll").prop('disabled', function(i, v){ return !v; });
}

function ClearAllTimeouts(){
	for (var i = 0; i < timeouts.length; i++){
		clearTimeout(timeouts[i]);
	}
}

function ResizeAll(action){
	$(".collapsible-jquery").each(function(index,element){
		if(action=="show"){
			$(this).siblings().toggle(true);
		}
		else{
			$(this).siblings().toggle(false);
		}
	});
}
</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="apply.cgi" target="hidden_frame">
<input type="hidden" name="current_page" value="Main_LogStatus_Content.asp">
<input type="hidden" name="next_page" value="Main_LogStatus_Content.asp">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="">
<input type="hidden" name="action_wait" value="">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
</form>
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">System Log - enhanced by Scribe</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">This page shows the detailed system's activities.</div>
<form method="post" name="config_form" action="start_apply.htm" target="hidden_frame">
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<tr>
<th width="20%">System Time</th>
<td>
<input type="text" id="system_time" name="system_time" size="40" class="devicepin" value="" readonly="1" style="font-size:12px;" autocorrect="off" autocapitalize="off">
<br><span id="dstzone" style="display:none;margin-left:5px;color:#FFFFFF;"></span>
</td>
</tr>
<tr>
<th>Uptime</th>
<td><span id="boot_days"></span> days <span id="boot_hours"></span> hours <span id="boot_minutes"></span> minute(s) <span id="boot_seconds"></span> seconds</td>
</tr>
<!--<tr style="display:none;">
<td>
<input type="hidden" name="current_page" value="Main_LogStatus_Content.asp">
<input type="hidden" name="next_page" value="Main_LogStatus_Content.asp">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="restart_logger">
<input type="hidden" name="action_wait" value="5">
<input type="text" maxlength="15" class="input_15_table" name="log_ipaddr" value="<% nvram_get("log_ipaddr"); %>" onkeypress="return validator.isIPAddr(this, event)" autocorrect="off" autocapitalize="off">
<label style="padding-left:15px;">Port:</label><input type="text" class="input_6_table" maxlength="5" name="log_port" onkeypress="return validator.isNumber(this,event);" onblur="validator.numberRange(this, 0, 65535);" value='<% nvram_get("log_port"); %>' autocorrect="off" autocapitalize="off">
</td>
</tr>
<tr style="display:none;">
<th><a class="hintstyle" href="javascript:void(0);" onclick="openHint(50,11);">Default message log level</a></th>
<td>
<select name="message_loglevel" class="input_option">
<option value="0" <% nvram_match("message_loglevel", "0", "selected"); %>>emergency</option>
<option value="1" <% nvram_match("message_loglevel", "1", "selected"); %>>alert</option>
<option value="2" <% nvram_match("message_loglevel", "2", "selected"); %>>critical</option>
<option value="3" <% nvram_match("message_loglevel", "3", "selected"); %>>error</option>
<option value="4" <% nvram_match("message_loglevel", "4", "selected"); %>>warning</option>
<option value="5" <% nvram_match("message_loglevel", "5", "selected"); %>>notice</option>
<option value="6" <% nvram_match("message_loglevel", "6", "selected"); %>>info</option>
<option value="7" <% nvram_match("message_loglevel", "7", "selected"); %>>debug</option>
</select>
</td>
</tr>
<tr style="display:none;">
<th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(50,12);">Log only messages more urgent than</a></th>
<td>
<select name="log_level" class="input_option">
<option value="1" <% nvram_match("log_level", "1", "selected"); %>>alert</option>
<option value="2" <% nvram_match("log_level", "2", "selected"); %>>critical</option>
<option value="3" <% nvram_match("log_level", "3", "selected"); %>>error</option>
<option value="4" <% nvram_match("log_level", "4", "selected"); %>>warning</option>
<option value="5" <% nvram_match("log_level", "5", "selected"); %>>notice</option>
<option value="6" <% nvram_match("log_level", "6", "selected"); %>>info</option>
<option value="7" <% nvram_match("log_level", "7", "selected"); %>>debug</option>
<option value="8" <% nvram_match("log_level", "8", "selected"); %>>all</option>
</select>
</td>
</tr>-->
</table>
<div class="apply_gen" valign="top" style="display:none;"><input class="button_gen" onclick="applySettings();" type="button" value="Apply" /></div>
</form>
<div style="line-height:10px;">&nbsp;</div>
<div style="color:#FFCC00;"><input type="checkbox" checked id="auto_refresh">Auto refresh</div>
<div style="color:#FFCC00;"><input type="checkbox" checked id="auto_scroll">Scroll to bottom on refresh?</div>
<table class="apply_gen">
<form name="formui_buttons">
<tr class="apply_gen" valign="top" align="center">
<td>
<input style="text-align:center;" id="btn_ShowAll" value="Show All" class="button_gen" onclick="ResizeAll('show')" type="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input style="text-align:center;" id="btn_HideAll" value="Hide All" class="button_gen" onclick="ResizeAll('hide')" type="button">
</td>
</tr>
<tr class="apply_gen" valign="top" align="center">
<td>
<input style="text-align:center;" id="btn_DownloadAll" value="Download All" class="button_gen" onclick="DownloadAllLogFile()" type="button">
</td>
</tr>
</form>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_messages">
<thead class="collapsible-jquery">
<tr><td colspan="2">System Messages (click to show/hide)</td></tr>
</thead>
<tr><td style="padding: 0px;">
<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_messages" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;"><% nvram_dump("syslog.log",""); %></textarea>
</td></tr>
<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="DownloadLogFile(this)" value="Download log file" class="button_gen btndownload" name="btnmessages" id="btnmessages">
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top"></td>
</tr>
</table>
<div id="footer"></div>
</body>
</html>
