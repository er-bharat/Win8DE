# Windows 8 revival on Linux.

If you are one of who enjoyed the windows 8 and miss its fluid animations but have since moved to linux.
And cant go back to windows 8, because all apps are non functional there. And if you can bear that you
cant install it on the newer hardware.
            This is for you it is a shell for wayland window managers like Labwc hyprland etc. It gives a
wallpaper utility, a lock screen, a start menu, an OSD for volume and brightness a settins app for wall.
it dosent provide charms menu because i always thought its useless.

## Screenshots

<img width="1920" height="1080" alt="start" src="https://github.com/user-attachments/assets/e8bc7877-165f-4028-bbfa-ae693064b118" />
<img width="1920" height="1080" alt="allapp" src="https://github.com/user-attachments/assets/77e450a7-e43e-43dd-9a3f-789c0eb6e52b" />
<img width="1920" height="1080" alt="lock-dialog" src="https://github.com/user-attachments/assets/60b711ff-a947-4ac4-bb07-df368f9fa13a" />
<img width="1920" height="1080" alt="lock-vkey" src="https://github.com/user-attachments/assets/10dbb0b8-5839-4c96-ba56-726a760ad5c2" />
<img width="1920" height="1080" alt="runningapps" src="https://github.com/user-attachments/assets/83ae8072-b697-4b3e-a1f9-b220b58e0424" />
<img width="1920" height="1080" alt="lock" src="https://github.com/user-attachments/assets/2afc4a9e-00e1-4baf-aea3-be8021915862" />

## Features
---
### Start
1. one command Win8Start to show hide start menu can be bound to super of compositor.
2. full drag and drop support of start tiles and sizes small medium large xlarge gui way right click.
3. can drag from all apps to tiles.
4. search of apps functional.
5. drag app from all apps to botom to hide start screen and put icon any where that supports like desktop.
6. get power menu by clicking user icon.
7. have battery osd in it.

### OSD
1. Volume up down mute
2. brightness up down.
3. two part Win8OSD-server and Win8OSD-client server should be autostarted
4. Win8OSD-client --volup voldown mute dispup dispdown

### Wall
1. simple image wallpaper
2. settable through settins

### Lockscreen
1. windows 8 style
2. wallpaper changable by settings app
3. have nice slide down and up of lockscreen
4. dont need click and drag just click is enough unlike original

### settings
1. can change wallpaper of all 3 graphically start wall lock
2. can change accent colors and background colors of start lockscreen etc.
---
## Installation ##

### for local binary use run

`./build.sh`

it will build all binaries and put it in "build/bin" folder you can use it in config files to autostart
and bind to system keys for brightness and volume with local location.
you can't run settings from start screen bc it uses system location so you will have to run it from binary built.
bind win/super key to Win8Start


### for system install

`./install.sh`

it will automatically run build.sh and move the binaries to "/usr/bin/" and will be available systemwide,
so it will be easier to put in configs and autostart

`./uninstall.sh`

it will remove binaries from `/usr/bin/`

## Use It Like seperate DE ##

it will use different config file so that your current config is not affected.
create a copy of config folder and paste it with diff name like labwc2 hypr2 etc.

find your compositors config loading command and make a .desktop file like this **example**.

`[Desktop Entry]`\
`Name=labwc-win8`\
`Comment=A wayland stacking compositor`\
`Exec=labwc -C /home/user1/.config/labwc3`\
`Icon=labwc`\
`Type=Application`\
`DesktopNames=labwc;wlroots`

and **paste** it in `/usr/share/wayland-sessions/`

and at ***login choose this session.***





