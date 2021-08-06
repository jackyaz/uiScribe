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
p{font-weight:bolder}thead.collapsible-jquery{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}thead.collapsible-jquery-config{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}.btndisabled{border:1px solid #999!important;background-color:#ccc!important;color:#000!important;background:#ccc!important;text-shadow:none!important;cursor:default!important}input.settingvalue{margin-left:3px!important}label.settingvalue{vertical-align:top!important;width:90px!important;display:inline-block!important}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script>
function showDST(){
	var system_timezone_dut = "<% nvram_get("time_zone"); %>";
	if(system_timezone_dut.search("DST") >= 0 && "<% nvram_get("time_zone_dst"); %>" == "1"){
	document.getElementById('dstzone').style.display = "";
	document.getElementById('dstzone').innerHTML = "* Daylight savings time is enabled in this time zone.";
	}
}

var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf("uiscribe") != -1 && prop.indexOf("uiscribe_version") == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}
var clockinterval,bootinterval,$j=jQuery.noConflict(),timeoutsenabled=!0;function showclock(){JS_timeObj.setTime(systime_millsec),systime_millsec+=1e3,JS_timeObj2=JS_timeObj.toString(),JS_timeObj2=JS_timeObj2.substring(0,3)+","+JS_timeObj2.substring(4,10)+" "+checkTime(JS_timeObj.getHours())+":"+checkTime(JS_timeObj.getMinutes())+":"+checkTime(JS_timeObj.getSeconds())+" "+JS_timeObj.getFullYear(),document.getElementById("system_time").value=JS_timeObj2,0<=navigator.appName.indexOf("Microsoft")&&(document.getElementById("log_messages").style.width="99%")}function showbootTime(){Days=Math.floor(boottime/86400),Hours=Math.floor(boottime/3600%24),Minutes=Math.floor(boottime%3600/60),Seconds=Math.floor(boottime%60),document.getElementById("boot_days").innerHTML=Days,document.getElementById("boot_hours").innerHTML=Hours,document.getElementById("boot_minutes").innerHTML=Minutes,document.getElementById("boot_seconds").innerHTML=Seconds,boottime+=1}function capitalise(a){return a.charAt(0).toUpperCase()+a.slice(1)}function GetCookie(a,b){if(null!=cookie.get("uiscribe_"+a))return cookie.get("uiscribe_"+a);return"string"==b?"":"number"==b?0:void 0}function SetCookie(a,b){cookie.set("uiscribe_"+a,b,3650)}$j.fn.serializeObject=function(){var a=custom_settings,b=[];$j.each($j("input[name=\"uiscribe_log_enabled\"]:checked"),function(){b.push(this.value)});var c=b.join(",");return a.uiscribe_logs_enabled=c,a};function SetCurrentPage(){document.config_form.next_page.value=window.location.pathname.substring(1),document.config_form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),ScriptUpdateLayout(),show_menu(),showclock(),showbootTime(),clockinterval=setInterval(showclock,1e3),bootinterval=setInterval(showbootTime,1e3),showDST(),get_conf_file()}function ScriptUpdateLayout(){var a=GetVersionNumber("local"),b=GetVersionNumber("server");$j("#uiscribe_version_local").text(a),a!=b&&"N/A"!=b&&($j("#uiscribe_version_server").text("Updated version available: "+b),showhide("btnChkUpdate",!1),showhide("uiscribe_version_server",!0),showhide("btnDoUpdate",!0))}function reload(){location.reload(!0)}function get_logfile(a){var b=a.replace(".log","");$j.ajax({url:"/ext/uiScribe/"+a+".htm",dataType:"text",timeout:3e3,error:function(){!0==timeoutsenabled&&!0==window["timeoutenabled_"+b]&&(window["timeout_"+b]=setTimeout(get_logfile,2e3,a))},success:function(c){!0==timeoutsenabled&&!0==window["timeoutenabled_"+b]&&("messages"==a?0<c.length&&(document.getElementById("log_"+a).innerHTML=c,document.getElementById("auto_scroll").checked&&$j("#log_"+a).scrollTop(9999999)):0<c.length&&(document.getElementById("log_"+a.substring(0,a.indexOf("."))).innerHTML=c,document.getElementById("auto_scroll").checked&&$j("#log_"+a.substring(0,a.indexOf("."))).scrollTop(9999999)),window["timeout_"+b]=setTimeout(get_logfile,3e3,a))}})}function get_conf_file(){$j.ajax({url:"/ext/uiScribe/logs.htm",timeout:2e3,dataType:"text",error:function(){setTimeout(get_conf_file,1e3)},success:function(a){var b=a.split("\n");b.sort(),b=b.filter(Boolean);for(var c,d="<tr id=\"rowenabledlogs\"><th width=\"40%\">Logs to display in WebUI</th><td class=\"settingvalue\">",e=0;e<b.length;e++)c=b[e].substring(b[e].lastIndexOf("/")+1),-1==c.indexOf("#")?(c=c.replace(".log","").replace(".htm","").trim(),d+="<input type=\"checkbox\" name=\"uiscribe_log_enabled\" id=\"uiscribe_log_enabled_"+c+"\" class=\"input settingvalue\" value=\""+c+"\" checked>",d+="<label for=\"uiscribe_log_enabled_"+c+"\" class=\"settingvalue\">"+c+"</label>"):(c=c.substring(0,c.indexOf("#")).replace(".log","").replace(".htm","").trim(),d+="<input type=\"checkbox\" name=\"uiscribe_log_enabled\" id=\"uiscribe_log_enabled_"+c+"\" class=\"input settingvalue\" value=\""+c+"\">",d+="<label for=\"uiscribe_log_enabled_"+c+"\" class=\"settingvalue\">"+c+"</label>"),0==(e+1)%4&&(d+="<br />");d+="</td></tr>",d+="<tr class=\"apply_gen\" valign=\"top\" height=\"35px\" id=\"rowsaveconfig\">",d+="<td colspan=\"2\" style=\"background-color:rgb(77,89,93);\">",d+="<input type=\"button\" onclick=\"SaveConfig();\" value=\"Save\" class=\"button_gen\" name=\"button\">",d+="</td></tr>",$j("#table_config").append(d),b.reverse();for(var f,e=0;e<b.length;e++)(f=b[e].indexOf("#"),-1==f)&&(c=b[e].substring(b[e].lastIndexOf("/")+1),$j("#table_messages").after(BuildLogTable(c)));AddEventHandlers()}})}function DownloadAllLogFile(){$j(".btndownload").each(function(){$j(this).trigger("click")})}function DownloadLogFile(b){$j(b).prop("disabled",!0),$j(b).addClass("btndisabled");var c="";c="btnmessages"==b.name?"/ext/uiScribe/messages.htm":"/ext/uiScribe/"+b.name.replace("btn","")+".log.htm",fetch(c).then(a=>a.blob()).then(c=>{const d=window.URL.createObjectURL(c),e=document.createElement("a");e.style.display="none",e.href=d,e.download=b.name.replace("btn","")+".log",document.body.appendChild(e),e.click(),window.URL.revokeObjectURL(d),$j(b).prop("disabled",!1),$j(b).removeClass("btndisabled")}).catch(()=>{console.log("File download failed!"),$j(b).prop("disabled",!1),$j(b).removeClass("btndisabled")})}function update_status(){$j.ajax({url:"/ext/uiScribe/detect_update.js",dataType:"script",timeout:3e3,error:function(){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("uiscribe_version_server",!0),"None"==updatestatus?($j("#uiscribe_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)):($j("#uiscribe_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_uiScribecheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.config_form.action_script.value="start_uiScribedoupdate",document.config_form.action_wait.value=10,showLoading(),document.config_form.submit()}function SaveConfig(){document.getElementById("amng_custom").value=JSON.stringify($j("config_form").serializeObject()),document.config_form.action_script.value="start_uiScribeconfig",document.config_form.action_wait.value=5,showLoading(),document.config_form.submit()}function GetVersionNumber(a){var b;return"local"==a?b=custom_settings.uiscribe_version_local:"server"==a&&(b=custom_settings.uiscribe_version_server),"undefined"==typeof b||null==b?"N/A":b}function BuildLogTable(a){var b="<div style=\"line-height:10px;\">&nbsp;</div>";return b+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#4D595D\" class=\"FormTable\" id=\"table_"+a.substring(0,a.indexOf("."))+"\">",b+="<thead class=\"collapsible-jquery\" id=\"thead_"+a.substring(0,a.indexOf("."))+"\"><tr><td colspan=\"2\">"+a+" (click to show/hide)</td></tr></thead>",b+="<tr><td style=\"padding: 0px;\">",b+="<textarea cols=\"63\" rows=\"27\" wrap=\"off\" readonly=\"readonly\" id=\"log_"+a.substring(0,a.indexOf("."))+"\" class=\"textarea_log_table\" style=\"font-family:'Courier New',Courier,mono; font-size:11px;\">Log file will display here. If you are seeing this message,it means the log file cannot be loaded.\r\nPlease check your USB to check the /opt/var/log directory exists.</textarea>",b+="</td></tr>",b+="<tr class=\"apply_gen\" valign=\"top\" height=\"35px\"><td style=\"background-color:rgb(77,89,93);border:0px;\">",b+="<input type=\"button\" onclick=\"DownloadLogFile(this);\" value=\"Download log file\" class=\"button_gen btndownload\" name=\"btn"+a.substring(0,a.indexOf("."))+"\" id=\"btn"+a.substring(0,a.indexOf("."))+"\">",b+="</td></tr>",b+="</table>",b}function AddEventHandlers(){$j(".collapsible-jquery").off("click").on("click",function(){var a=$j(this).prop("id").replace("thead_","");"messages"!=a&&(a+=".log");var b=a.replace(".log","");!0==$j(this).siblings().is(":hidden")?(window["timeoutenabled_"+b]=!0,get_logfile(a)):(clearTimeout(window["timeout_"+b]),window["timeoutenabled_"+b]=!1),$j(this).siblings().toggle("fast")}),ResizeAll("hide"),$j("#thead_messages").trigger("click"),$j(".collapsible-jquery-config").off("click").on("click",function(){$j(this).siblings().toggle("fast",function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")})}),$j(".collapsible-jquery-config").each(function(){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)})}function ToggleRefresh(){!0==$j("#auto_refresh").prop("checked")?($j("#auto_scroll").prop("disabled",!1),timeoutsenabled=!0,$j(".collapsible-jquery").each(function(){var a=$j(this).prop("id").replace("thead_","");"messages"!=a&&(a+=".log"),!1==$j(this).siblings().is(":hidden")&&get_logfile(a)})):($j("#auto_scroll").prop("disabled",!0),timeoutsenabled=!1)}function ResizeAll(a){$j(".collapsible-jquery").each(function(){if("show"==a){$j(this).siblings().toggle(!0);var b=$j(this).prop("id").replace("thead_","");window["timeoutenabled_"+b]=!0,"messages"!=b&&(b+=".log"),get_logfile(b)}else{$j(this).siblings().toggle(!1);var b=$j(this).prop("id").replace("thead_","");window["timeoutenabled_"+b]=!1,clearTimeout(window["timeout_"+b])}})}
</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="apply.cgi" target="hidden_frame">
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
<form method="post" name="config_form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="15">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<thead class="collapsible-jquery-config" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="uiscribe_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="uiscribe_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery-config" id="systeminfo">
<tr><td colspan="2">System Info (click to expand/collapse)</td></tr>
</thead>
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
<tr style="display:none;">
<td>
<input type="text" maxlength="15" class="input_15_table" name="log_ipaddr" value="<% nvram_get("log_ipaddr"); %>" onkeypress="return validator.isIPAddr(this, event)" autocorrect="off" autocapitalize="off">
<label style="padding-left:15px;">Port:</label><input type="text" class="input_6_table" maxlength="5" name="log_port" onkeypress="return validator.isNumber(this,event);" onblur="validator.numberRange(this, 0, 65535);" value="<% nvram_get('log_port'); %>" autocorrect="off" autocapitalize="off">
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
<th><a class="hintstyle" href="javascript:void(0);" onclick="openHint(50,12);">Log only messages more urgent than</a></th>
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
</tr>
<tr class="apply_gen" valign="top" style="display:none;"><td><input class="button_gen" onclick="applySettings();" type="button" value="Apply" /></td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery-config" id="scriptconfig">
<tr><td colspan="2">General Configuration (click to expand/collapse)</td></tr>
</thead>
</table>
</form>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery-config" id="tablelogs">
<tr><td colspan="2">Logs (click to expand/collapse)</td></tr>
</thead>
<tr><td style="padding-left:4px;">
<div style="color:#FFCC00;"><input type="checkbox" checked id="auto_refresh" onclick="ToggleRefresh();">Auto refresh&nbsp;&nbsp;&nbsp;<input type="checkbox" checked id="auto_scroll">Scroll to bottom on refresh?</div>
<table class="apply_gen" style="margin-top:0px;">
<form name="formui_buttons">
<tr class="apply_gen" valign="top" align="center">
<td style="border:0px;">
<input style="text-align:center;" id="btn_ShowAll" value="Show All" class="button_gen" onclick="ResizeAll('show');" type="button">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input style="text-align:center;" id="btn_HideAll" value="Hide All" class="button_gen" onclick="ResizeAll('hide');" type="button">
</td>
</tr>
<tr class="apply_gen" valign="top" align="center">
<td style="border:0px;">
<input style="text-align:center;" id="btn_DownloadAll" value="Download All" class="button_gen" onclick="DownloadAllLogFile();" type="button">
</td>
</tr>
</form>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_messages">
<thead class="collapsible-jquery" id="thead_messages">
<tr><td colspan="2">System Messages (click to show/hide)</td></tr>
</thead>
<tr><td style="padding: 0px;">
<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_messages" class="textarea_log_table" style="font-family:'Courier New', Courier, mono; font-size:11px;"><% nvram_dump("syslog.log",""); %></textarea>
</td></tr>
<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77, 89, 93);border:0px;">
<input type="button" onclick="DownloadLogFile(this);" value="Download log file" class="button_gen btndownload" name="btnmessages" id="btnmessages">
</td>
</tr>
</table>
</tr>
</td>
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
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>
