var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)
var timeoutsenabled = true;

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

function capitalise(string){
	return string.charAt(0).toUpperCase() + string.slice(1);
}

function GetCookie(cookiename,returntype){
	var s;
	if((s = cookie.get("uiscribe_"+cookiename)) != null){
		return cookie.get("uiscribe_"+cookiename);
	}
	else{
		if(returntype == "string"){
			return "";
		}
		else if(returntype == "number"){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue){
	cookie.set("uiscribe_"+cookiename, cookievalue, 31);
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	
	var logsenabled = [];
	$j.each($j("input[name='uiscribe_log_enabled']:checked"), function(){
		logsenabled.push(this.value);
	});
	var logsenabledstring = logsenabled.join(",");
	o["uiscribe_logs_enabled"] = logsenabledstring;
	return o;
};

function SetCurrentPage(){
	document.config_form.next_page.value = window.location.pathname.substring(1);
	document.config_form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	LoadCustomSettings();
	ScriptUpdateLayout();
	show_menu();
	showclock();
	showbootTime();
	showDST();
	get_conf_file();
}

function ScriptUpdateLayout(){
	var localver = GetVersionNumber("local");
	var serverver = GetVersionNumber("server");
	$j("#scripttitle").text($j("#scripttitle").text()+" - "+localver);
	$j("#uiscribe_version_local").text(localver);
	
	if(localver != serverver && serverver != "N/A"){
		$j("#uiscribe_version_server").text("Updated version available: "+serverver);
		showhide("btnChkUpdate", false);
		showhide("uiscribe_version_server", true);
		showhide("btnDoUpdate", true);
	}
}

function reload(){
	location.reload(true);
}

function get_logfile(filename){
	var filenamesafe = filename.replace(".log","");
	$j.ajax({
		url: '/ext/uiScribe/'+filename+'.htm',
		dataType: 'text',
		timeout: 3000,
		error: function(xhr){
			if(timeoutsenabled == true && window["timeoutenabled_"+filenamesafe] == true){
				window["timeout_"+filenamesafe] = setTimeout(get_logfile, 2000, filename);
			}
		},
		success: function(data){
			if(timeoutsenabled == true && window["timeoutenabled_"+filenamesafe] == true){
				if(filename != "messages"){
					if(data.length > 0){
						document.getElementById("log_"+filename.substring(0,filename.indexOf("."))).innerHTML = data;
						if (document.getElementById("auto_scroll").checked){
							$j("#log_"+filename.substring(0,filename.indexOf("."))).scrollTop(9999999);
						}
					}
				}
				else{
					if(data.length > 0){
						document.getElementById("log_"+filename).innerHTML = data;
						if (document.getElementById("auto_scroll").checked){
							$j("#log_"+filename).scrollTop(9999999);
						}
					}
				}
				window["timeout_"+filenamesafe] = setTimeout(get_logfile, 3000, filename);
			}
		}
	});
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/uiScribe/logs.htm',
		timeout: 2000,
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_conf_file, 1000);
		},
		success: function(data){
			var logs=data.split("\n");
			logs.sort();
			logs=logs.filter(Boolean);
			
			var logconfigtablehtml='<tr id="rowenabledlogs"><th width="40%">Logs to display in WebUI</th><td class="settingvalue">';
			
			for (var i = 0; i < logs.length; i++){
				var filename=logs[i].substring(logs[i].lastIndexOf("/")+1);
				if(filename.indexOf("#") != -1){
					filename = filename.substring(0,filename.indexOf("#")).replace(".log","").replace(".htm","").trim();
					logconfigtablehtml+='<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+ filename +'" class="input settingvalue" value="'+filename+'">';
					logconfigtablehtml+='<label for="uiscribe_log_enabled_'+ filename +'" class="settingvalue">'+filename+'</label>';
				}
				else{
					filename = filename.replace(".log","").replace(".htm","").trim();
					logconfigtablehtml+='<input type="checkbox" name="uiscribe_log_enabled" id="uiscribe_log_enabled_'+ filename +'" class="input settingvalue" value="'+filename+'" checked>';
					logconfigtablehtml+='<label for="uiscribe_log_enabled_'+ filename +'" class="settingvalue">'+filename+'</label>';
				}
				if((i+1) % 4 == 0){
					logconfigtablehtml+='<br />';
				}
			}
			
			logconfigtablehtml+='</td></tr>';
			logconfigtablehtml+='<tr class="apply_gen" valign="top" height="35px" id="rowsaveconfig">';
			logconfigtablehtml+='<td colspan="2" style="background-color:rgb(77, 89, 93);">';
			logconfigtablehtml+='<input type="button" onclick="SaveConfig();" value="Save" class="button_gen" name="button">';
			logconfigtablehtml+='</td></tr>';
			$j("#table_config").append(logconfigtablehtml);
			logs.reverse();
			
			for (var i = 0; i < logs.length; i++){
				var commentstart=logs[i].indexOf("#");
				if (commentstart != -1){
					continue
				}
				filename=logs[i].substring(logs[i].lastIndexOf("/")+1);
				$j("#table_messages").after(BuildLogTable(filename));
			}
			
			AddEventHandlers();
		}
	});
}

function DownloadAllLogFile(){
	$j(".btndownload").each(function(index){$j(this).trigger("click");});
}

function DownloadLogFile(btnlog){
	$j(btnlog).prop('disabled', true);
	$j(btnlog).addClass("btndisabled");
	var filepath = "";
	if(btnlog.name == "btnmessages"){
		filepath='/ext/uiScribe/messages.htm';
	}
	else{
		filepath='/ext/uiScribe/'+btnlog.name.replace("btn","")+'.log.htm';
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
		$j(btnlog).prop('disabled', false);
		$j(btnlog).removeClass("btndisabled");
	})
	.catch(() => {
		console.log('File download failed!');
		$j(btnlog).prop('disabled', false);
		$j(btnlog).removeClass("btndisabled");
	});
}

function update_status(){
	$j.ajax({
		url: '/ext/uiScribe/detect_update.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(update_status, 1000);
		},
		success: function(){
			if(updatestatus == "InProgress"){
				setTimeout(update_status, 1000);
			}
			else{
				document.getElementById("imgChkUpdate").style.display = "none";
				showhide("uiscribe_version_server", true);
				if(updatestatus != "None"){
					$j("#uiscribe_version_server").text("Updated version available: "+updatestatus);
					showhide("btnChkUpdate", false);
					showhide("btnDoUpdate", true);
				}
				else{
					$j("#uiscribe_version_server").text("No update available");
					showhide("btnChkUpdate", true);
					showhide("btnDoUpdate", false);
				}
			}
		}
	});
}

function CheckUpdate(){
	showhide("btnChkUpdate", false);
	document.formScriptActions.action_script.value="start_uiScribecheckupdate";
	document.formScriptActions.submit();
	document.getElementById("imgChkUpdate").style.display = "";
	setTimeout(update_status, 2000);
}

function DoUpdate(){
	var action_script_tmp = "start_uiScribedoupdate";
	document.config_form.action_script.value = action_script_tmp;
	var restart_time = 10;
	document.config_form.action_wait.value = restart_time;
	showLoading();
	document.config_form.submit();
}

function SaveConfig(){
	document.getElementById('amng_custom').value = JSON.stringify($j('config_form').serializeObject());
	var action_script_tmp = "start_uiScribeconfig";
	document.config_form.action_script.value = action_script_tmp;
	var restart_time = 5;
	document.config_form.action_wait.value = restart_time;
	showLoading();
	document.config_form.submit();
}

function GetVersionNumber(versiontype){
	var versionprop;
	if(versiontype == "local"){
		versionprop = custom_settings.uiscribe_version_local;
	}
	else if(versiontype == "server"){
		versionprop = custom_settings.uiscribe_version_server;
	}
	
	if(typeof versionprop == 'undefined' || versionprop == null){
		return "N/A";
	}
	else{
		return versionprop;
	}
}

function BuildLogTable(name){
	var loghtml='<div style="line-height:10px;">&nbsp;</div>';
	loghtml+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#4D595D" class="FormTable" id="table_'+name.substring(0,name.indexOf("."))+'">';
	loghtml+='<thead class="collapsible-jquery" id="thead_'+name.substring(0,name.indexOf("."))+'"><tr><td colspan="2">'+name+' (click to show/hide)</td></tr></thead>';
	loghtml+='<tr><td style="padding: 0px;">';
	loghtml+='<textarea cols="63" rows="27" wrap="off" readonly="readonly" id="log_'+name.substring(0,name.indexOf("."))+'" class="textarea_log_table" style="font-family:\'Courier New\', Courier, mono; font-size:11px;">Log file will display here. If you are seeing this message, it means the log file cannot be loaded.\r\nPlease check your USB to check the /opt/var/log directory exists.</textarea>';
	loghtml+='</td></tr>';
	loghtml+='<tr class="apply_gen" valign="top" height="35px"><td style="background-color:rgb(77, 89, 93);border:0px;">';
	loghtml+='<input type="button" onclick="DownloadLogFile(this);" value="Download log file" class="button_gen btndownload" name="btn'+name.substring(0,name.indexOf("."))+'" id="btn'+name.substring(0,name.indexOf("."))+'">';
	loghtml+='</td></tr>';
	loghtml+='</table>';
	return loghtml;
}

function AddEventHandlers(){
	$j(".collapsible-jquery").click(function(){
		var filename = $j(this).prop("id").replace("thead_","");
		if(filename != "messages"){
			filename+=".log";
		}
		var filenamesafe = filename.replace(".log","");
		if($j(this).siblings().is(":hidden") == true){
			window["timeoutenabled_"+filenamesafe] = true;
			get_logfile(filename);
		}
		else{
			clearTimeout(window["timeout_"+filenamesafe]);
			window["timeoutenabled_"+filenamesafe] = false;
		}
		$j(this).siblings().toggle("fast");
	});
	
	$j(".collapsible-jquery-config").click(function(){
		$j(this).siblings().toggle("fast",function(){
			if($j(this).css("display") == "none"){
				SetCookie($j(this).siblings()[0].id,"collapsed");
			}
			else{
				SetCookie($j(this).siblings()[0].id,"expanded");
			}
		})
	});
	
	$j(".collapsible-jquery-config").each(function(index,element){
		if(GetCookie($j(this)[0].id,"string") == "collapsed"){
			$j(this).siblings().toggle(false);
		}
		else{
			$j(this).siblings().toggle(true);
		}
	});
	
	ResizeAll("hide");
	
	$j("#thead_messages").trigger("click");
}

function ToggleRefresh(){
	if($j("#auto_refresh").prop('checked') == true){
		$j("#auto_scroll").prop('disabled',false)
		timeoutsenabled=true;
		
		$j(".collapsible-jquery").each(function(index,element){
			var filename = $j(this).prop("id").replace("thead_","");
			if(filename != "messages"){
				filename+=".log";
			}
			if($j(this).siblings().is(":hidden") == false){
				get_logfile(filename);
			}
		});
	}
	else{
		$j("#auto_scroll").prop('disabled',true)
		timeoutsenabled=false;
	}
}

function ResizeAll(action){
	$j(".collapsible-jquery").each(function(index,element){
		if(action=="show"){
			$j(this).siblings().toggle(true);
			var filename = $j(this).prop("id").replace("thead_","");
			window["timeoutenabled_"+filename] = true;
			if(filename != "messages"){
				filename+=".log";
			}
			get_logfile(filename);
		}
		else{
			$j(this).siblings().toggle(false);
			var filename = $j(this).prop("id").replace("thead_","");
			window["timeoutenabled_"+filename] = false;
			clearTimeout(window["timeout_"+filename]);
		}
	});
}
