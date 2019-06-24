# uiScribe - Custom System Log page to show output from "scribed" logs
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c705507fb1d845d9937e98f0b6e15997)](https://www.codacy.com/app/jackyaz/uiScribe?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/uiScribe&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/uiScribe.svg?branch=master)](https://travis-ci.com/jackyaz/uiScribe)

## v1.1.0
### Updated on 2019-06-23
## About
Customise the System Log page to show log files created by Scribe (syslog-ng). Requires [**Scribe**](https://github.com/cynicastic/scribe)
Support for Scribe can be found here: [Scribe on SNBForums](https://www.snbforums.com/threads/scribe-syslog-ng-and-logrotate-installer.55853/)

uiScribe is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

Example log page (sections added/removed dynamically depending on which filters you have installed in Scribe)
![Menu UI](https://puu.sh/DE3ou/7b836b07d5.png)

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!
[**PayPal donation**](https://paypal.me/jackyaz21)

## Supported Models
All modes supported by [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). Models confirmed to work are below:
*   RT-AC86U

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/uiScribe/master/uiScribe.sh" -o "/jffs/scripts/uiScribe" && chmod 0755 /jffs/scripts/uiScribe && /jffs/scripts/uiScribe install
```

## Usage
To launch the uiScribe menu after installation, use:
```sh
uiScribe
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/uiScribe
```

## Updating
Launch uiScribe and select option u

## Help
Please post about any issues and problems here: [uiScribe on SNBForums](https://www.snbforums.com/threads/uiscribe-custom-system-log-page-for-scribed-logs.57040/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
