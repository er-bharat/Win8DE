import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

pragma ComponentBehavior: Bound

ApplicationWindow {

    id: mainwindow
    visible: false
    width: screen.width
    height: screen.height
    title: "Linux Start Menu Clone"
    color: "#180052"  // background color in case no wallpaper
    // start wallpaper
    Image {
        id: background
        anchors.fill: parent
        source: startWallpaper // choose from Win8Settings
        fillMode: Image.PreserveAspectCrop
    }
    
    Keys.onTabPressed: {
        container.forceActiveFocus()
    }

    // area at bottom to hide the start screen on click
    MouseArea {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 100
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        
        onClicked: (mouse)=>{
            WindowController.hide()  //c++ function to hide the mainwindow.
        }
    }

    // hide when reach to bottom with holding a desktop file to be put somewhere like desktop or editor.
    DropArea {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 100
        z: 0
        onEntered: {
            WindowController.hide()
        }
    }
    // main start screen
    Item {
        anchors.fill: parent
        
        Text {
            id: start
            text: "Start"
            color: "white"
            font.pixelSize: 60
            font.weight: Font.Thin
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 30
            anchors.leftMargin: 120
            anchors.topMargin: 50
        }
        
        // Battery display next to "Start"
        Item {
            id: batteryDisplay
            width: 120
            height: 40
            anchors.verticalCenter: userCard.verticalCenter
            anchors.right: userCard.left
            anchors.rightMargin: 40
            
            // Battery fill
            Rectangle {
                id: batteryFill
                x: batteryOutline.x + 2
                y: batteryOutline.y + 2
                height: batteryOutline.height - 4
                width: (batteryOutline.width - 4) * Math.min(Math.max(battery.percent / 100, 0), 1)
                radius: 0
                color: battery.charging ? "#FFD700"  // gold/yellow for charging
                : battery.percent < 20 ? "#FF4C4C" // red for low
                : "white"  // green for normal
                smooth: true
            }
            
            // Outer battery shape
            Rectangle {
                id: batteryOutline
                width: 50
                height: 30
                radius: 0
                color: "transparent"
                border.color: "white"
                border.width: 4
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // Battery tip (small rounded rectangle)
            Rectangle {
                width: 6
                height: batteryOutline.height / 2
                radius: 0
                color: "#CCCCCC"
                anchors.left: batteryOutline.right
                anchors.verticalCenter: batteryOutline.verticalCenter
            }
            
            // Percent text
            Text {
                text: battery.percent >= 0 ? battery.percent + "%" : "N/A"
                color: "#FFFFFF"
                font.pixelSize: 30
                font.weight: Font.Thin
                anchors.verticalCenter: batteryOutline.verticalCenter
                anchors.left: batteryOutline.right
                anchors.leftMargin: 12
            }
            
            // Optional: subtle shadow behind battery
            Rectangle {
                anchors.fill: batteryOutline
                radius: batteryOutline.radius
                color: "transparent"
                border.color: "transparent"
                
            }
        }
        // the user icon at top right hosts power menu and settings.
        Item {
            id: userCard
            width: 150
            height: 50
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 30
            anchors.rightMargin: 120
            anchors.topMargin: 50
            
            Row {
                spacing: 12
                anchors.centerIn: parent
                
                Text {
                    text: AppLauncher.getCurrentUser()
                    color: "white"
                    font.pixelSize: 40
                    font.weight: Font.Thin
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    width: 48
                    height: 48
                    color: Win8Colors.Tile

                    //backup user icon
                    Image {
                        id: userIcon
                        source: "icons/peoplew.png"
                        width: 48
                        height: 48
                        fillMode: Image.PreserveAspectFit
                    }
                    //icon set for linux account.
                    Image {
                        id: userIcon2
                        source: "file:///var/lib/AccountsService/icons/" + AppLauncher.getCurrentUser()
                        width: 48
                        height: 48
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
            // powermenu shutdown power logout etc
            Menu {
                id: powerMenu
                
                MenuItem {
                    text: "Suspend"
                    icon.source: "/icons/suspend.svg"
                    onTriggered: powerControl.suspend()
                }
                
                MenuItem {
                    text: "Logout"
                    icon.source: "/icons/logout.svg"
                    onTriggered: powerControl.logout()
                }
                
                MenuItem {
                    text: "Reboot"
                    icon.source: "/icons/reboot.svg"
                    onTriggered: powerControl.reboot()
                }
                
                MenuItem {
                    text: "Shutdown"
                    icon.source: "/icons/shutdown.svg"
                    onTriggered: powerControl.shutdown()
                }
                
                MenuSeparator {}
                
                MenuItem {
                    text: "Settings"
                    icon.source: "/icons/settings.svg"
                    onTriggered: {
                        Launcher.launch("Win8Settings")
                        WindowController.hide()
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse)=>{
                    powerMenu.popup()
                }
            }
        }
        // button to open all apps section.
        Rectangle {
            id: allAppsButton
            width: 50
            height: 50
            radius: width/2
            border.width: 2
            border.color: "white"
            color: "transparent"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 30
            anchors.leftMargin: 120
            
            Image {
                id: iconImg
                anchors.centerIn: parent
                width: 40
                height: 40
                source: "icons/go-down-skip.svg"
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                Timer {
                    id: refreshTimer
                    interval: 500
                    repeat: false
                    running: false
                    onTriggered: {
                        AppLauncher.refreshApplications()
                    }
                }
                // show allapparea focus the grid and once refresh the list.
                onClicked: {
                    allapparea.y = 0
                    appGridView.focus = true
                    refreshTimer.start()
                    // searchField.focus = true
                }
            }
        }
        // holds the area in which the flickable lives
        Item {
            id: tilearea
            // anchors.verticalCenter: parent.verticalCenter
            anchors.top: start.bottom
            anchors.bottom: allAppsButton.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 120
            anchors.topMargin: 30
            anchors.bottomMargin: 30
            width: parent.width-120
            Flickable {
                id: container
                width: parent.width
                height: parent.height
                contentWidth: parent.width * 2  //allows 2x width of screen for tiles so that it can have scrollin.
                contentHeight: parent.height
                clip: !anyTileLaunching
                
                Behavior on contentX {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
                
                focus: true                       // KEYBOARD NAVIGATION
                activeFocusOnTab: true            // KEYBOARD NAVIGATION
                property bool anyTileLaunching: false
                property int gridSize: tilearea.height/5
                property int halfGrid: gridSize / 2
                property int cols: Math.floor(width / halfGrid)
                property int focusedIndex: -1
                
                Component.onCompleted: {
                    Qt.callLater(() => {
                        const tolerance = Math.max(2, container.halfGrid * 0.15)
                        // ~15% of grid or minimum 2px
                        
                        for (let i = 0; i < tileRepeater.count; ++i) {
                            const t = tileRepeater.itemAt(i)
                            if (!t) continue
                                container.snapIfSlightlyOff(t, tolerance)
                        }
                    })
                }
                
                
                function nearestFreeSnap(x, y, tileWidth, tileHeight, excludeIndex) {
                    const grid = halfGrid
                    
                    // snap using TOP-LEFT only
                    const baseX = Math.round(x / grid) * grid
                    const baseY = Math.round(y / grid) * grid
                    
                    // collect occupied rects
                    let occupied = []
                    for (let i = 0; i < tileRepeater.count; ++i) {
                        if (i === excludeIndex) continue
                            let t = tileRepeater.itemAt(i)
                            if (!t) continue
                                occupied.push({
                                    x: t.x, y: t.y,
                                    w: t.width, h: t.height
                                })
                    }
                    
                    function intersects(px, py) {
                        for (let o of occupied) {
                            if (px < o.x + o.w &&
                                px + tileWidth > o.x &&
                                py < o.y + o.h &&
                                py + tileHeight > o.y) {
                                return true
                                }
                        }
                        return false
                    }
                    
                    // if snapped position is valid → done
                    if (!intersects(baseX, baseY))
                        return Qt.point(baseX, baseY)
                        
                        // generate nearby candidates (small movement only)
                        let candidates = []
                        const maxSteps = 4   // limits how far a tile can move
                        
                        for (let dy = -maxSteps; dy <= maxSteps; ++dy) {
                            for (let dx = -maxSteps; dx <= maxSteps; ++dx) {
                                if (dx === 0 && dy === 0) continue
                                    
                                    let nx = baseX + dx * grid
                                    let ny = baseY + dy * grid
                                    
                                    if (nx < 0 || ny < 0) continue
                                        if (nx + tileWidth > contentWidth) continue
                                            
                                            candidates.push({
                                                x: nx,
                                                y: ny,
                                                dist: Math.abs(dx) + Math.abs(dy) // minimal movement bias
                                            })
                            }
                        }
                        
                        // sort by closest movement first
                        candidates.sort((a, b) => a.dist - b.dist)
                        
                        // pick nearest free slot
                        for (let c of candidates) {
                            if (!intersects(c.x, c.y))
                                return Qt.point(c.x, c.y)
                        }
                        
                        // fallback → original snapped position
                        return Qt.point(baseX, baseY)
                }
                
                
                // keeps the focused item in view when using keyboard navigation.
                function ensureVisible(index) {
                    let t = tileRepeater.itemAt(index)
                    if (!t) return
                        if (t.x < contentX)
                            contentX = t.x
                            else if (t.x + t.width > contentX + width)
                                contentX = t.x + t.width - width
                }
                
                
                Keys.onPressed: (event) => {
                    if (tileRepeater.count === 0)
                        return
                        if (focusedIndex < 0)
                            focusedIndex = 0
                            let currentItem = tileRepeater.itemAt(focusedIndex)
                            if (!currentItem)
                                return
                                
                                function distance(a, b) {
                                    return Math.hypot(a.x - b.x, a.y - b.y);
                                }
                                
                                function findNext(dx, dy) {
                                    let best = -1;
                                    let bestDist = Infinity;
                                    let fallback = -1;
                                    let fallbackDist = Infinity;
                                    
                                    const cx = currentItem.x + currentItem.width / 2;
                                    const cy = currentItem.y + currentItem.height / 2;
                                    const cLeft = currentItem.x;
                                    const cRight = currentItem.x + currentItem.width;
                                    const cTop = currentItem.y;
                                    const cBottom = currentItem.y + currentItem.height;
                                    
                                    for (let i = 0; i < tileRepeater.count; ++i) {
                                        if (i === focusedIndex)
                                            continue;
                                        
                                        let item = tileRepeater.itemAt(i);
                                        if (!item)
                                            continue;
                                        
                                        const ix = item.x + item.width / 2;
                                        const iy = item.y + item.height / 2;
                                        const iLeft = item.x;
                                        const iRight = item.x + item.width;
                                        const iTop = item.y;
                                        const iBottom = item.y + item.height;
                                        
                                        const vx = ix - cx;
                                        const vy = iy - cy;
                                        
                                        // Direction filter
                                        if ((dx !== 0 && Math.sign(vx) !== dx) ||
                                            (dy !== 0 && Math.sign(vy) !== dy))
                                            continue;
                                            
                                        // Axis-alignment check using edges
                                        let aligned = false;
                                        if (dx !== 0) {
                                            // LEFT/RIGHT: check if vertical spans overlap
                                            aligned = !(cBottom < iTop || cTop > iBottom);
                                        } else {
                                            // UP/DOWN: check if horizontal spans overlap
                                            aligned = !(cRight < iLeft || cLeft > iRight);
                                        }
                                        
                                        const dist = distance({x: ix, y: iy}, {x: cx, y: cy});
                                        
                                        if (aligned) {
                                            if (dist < bestDist) {
                                                bestDist = dist;
                                                best = i;
                                            }
                                        } else {
                                            if (dist < fallbackDist) {
                                                fallbackDist = dist;
                                                fallback = i;
                                            }
                                        }
                                    }
                                    return best !== -1 ? best : fallback;
                                }
                                let next = -1

                                switch (event.key) {
                                    case Qt.Key_Left:
                                        next = findNext(-1, 0)
                                        break
                                    case Qt.Key_Right:
                                        next = findNext(1, 0)
                                        break
                                    case Qt.Key_Up:
                                        next = findNext(0, -1)
                                        break
                                    case Qt.Key_Down:
                                        next = findNext(0, 1)
                                        break
                                    case Qt.Key_A:
                                        // Check for Ctrl modifier
                                        if (event.modifiers & Qt.ControlModifier) {
                                            allapparea.y = 0
                                            appGridView.focus = true
                                            refreshTimer.start()
                                            event.accepted = true
                                        }
                                        break
                                    case Qt.Key_PageDown:
                                        allapparea.y = 0
                                        appGridView.focus = true
                                        refreshTimer.start()
                                        break
                                    case Qt.Key_Return:
                                    case Qt.Key_Enter:
                                    case Qt.Key_Space:
                                        currentItem.launch()
                                        
                                        event.accepted = true
                                        return
                                }
                                
                                if (next !== -1) {
                                    focusedIndex = next
                                    ensureVisible(next)
                                    event.accepted = true
                                }
                }
                // >>> END KEYBOARD NAVIGATION <<<
                // touchpad and mouse wheel behaviour
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: false
                    propagateComposedEvents: true
                        
                    onWheel: function(wheel) {
                        let isTouchpad = wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0
                            
                        // Touchpad vertical top opens allapparea
                        if (isTouchpad && wheel.pixelDelta.y < 0) {
                            allapparea.y = 0
                            appGridView.focus = true
                            refreshTimer.start()
                        }
                        // Horizontal scrolling
                        let delta = 0
                        if (isTouchpad) {
                            // Touchpad: horizontal ONLY
                            delta = -wheel.pixelDelta.x * 10
                        } else {
                            // Mouse wheel: original behavior
                            delta = -(wheel.angleDelta.y + wheel.angleDelta.x)
                        }
                            
                        if (delta !== 0) {
                            let newX = container.contentX + delta
                            newX = Math.max(0,
                                            Math.min(newX,
                                                     container.contentWidth - container.width))
                            container.contentX = newX
                            wheel.accepted = true
                        }
                    }
                }
                //Recieves desktop files to place on new tiles.
                DropArea {
                    anchors.fill: parent
                    
                    onDropped: (drop) => {
                        if (!drop.hasUrls)
                            return
                            
                            for (let i = 0; i < drop.urls.length; ++i) {
                                const url = drop.urls[i]
                                if (!url.toString().endsWith(".desktop"))
                                    continue
                                    
                                    const localPath = url.toString().replace("file://", "")
                                    
                                    // default (medium tile)
                                    const tileW = container.halfGrid * 2 - 5
                                    const tileH = tileW
                                    
                                    // mouse is CENTER of tile → convert to top-left
                                    const hintX = drop.x - tileW / 2
                                    const hintY = drop.y - tileH / 2
                                    
                                    const p = container.nearestFreeSnap(
                                        hintX,
                                        hintY,
                                        tileW,
                                        tileH,
                                        -1
                                    )
                                    
                                    tileModel.addTileFromDesktopFile(localPath, p.x, p.y)
                            }
                    }
                }
                
                
                Repeater {
                    id: tileRepeater
                    model: tileModel
                        
                    Rectangle {
                        id: tile
                        z: (launching || dragArea.dragging) ? 200 : 0
                            
                        // --- Size handling ---
                            
                        required property int index
                        required property real modelX
                        required property real modelY
                        required property string name
                        required property string icon
                        required property string command
                        required property string size
                        required property bool terminal
                        required property string tileColor
                        required property string tileQml
                        required property bool qmlEnabled
                            
                        //size setup of tiles.
                        readonly property int smallSize:   container.halfGrid - 5
                        readonly property int mediumSize:  container.halfGrid * 2 - 5
                        readonly property int largeWidth:  container.halfGrid * 4 - 5
                        readonly property int largeHeight: container.halfGrid * 2 - 5
                        readonly property int xlargeSize:  container.halfGrid * 4 - 5   // 4x4 tile
                        
                        width:  size === "small"   ? smallSize
                        : size === "medium"  ? mediumSize
                        : size === "large"   ? largeWidth
                        : size === "xlarge"  ? xlargeSize
                        : mediumSize
                            
                        height: size === "small"   ? smallSize
                        : size === "medium"  ? mediumSize
                        : size === "large"   ? largeHeight
                        : size === "xlarge"  ? xlargeSize
                        : mediumSize
                            
                        x: modelX
                        y: modelY
                        
                        property bool hovered: false
                        
                        readonly property color effectiveColor:
                        tileColor && tileColor.length > 0
                        ? tileColor
                        : Win8Colors.Tile
                        
                        
                        color: dragArea.dragging || container.focusedIndex === index || hovered
                        ? Qt.lighter(effectiveColor, 1.3)
                        : effectiveColor
                        
                        border.width: 1
                        border.color: container.focusedIndex === index || hovered
                        ? "#949494"
                        : Qt.rgba(1,1,1,0.2)
                        
                        Behavior on color {
                            ColorAnimation { duration: 180 }
                        }
                           
                        ColorDialog {
                            id: dialog
                            title: "Choose Tile Color"
                            
                            onAccepted: {
                                tileModel.setTileColor(tile.index, selectedColor)
                                WindowController.show()
                            }
                            onRejected: {
                                WindowController.show()
                            }
                        }
                        
                            
                        function launch() {
                            if (tile.launching)
                                return
                                    
                                tile.launching = true
                                container.anyTileLaunching = true
                                AppLauncher.launchApp(tile.command, tile.terminal)
                        }
                        
                        
                        //-----------------------------------------------------------
                        // LAUNCH ANIMATION PROPERTIES
                        //-----------------------------------------------------------
                        property bool launching: false
                            
                        // fixed center target
                        property real finalX: container.contentX + container.width  / 2 - width  / 2 - 60
                        property real finalY: container.contentY + container.height / 2 - height / 2 -(start.height-allAppsButton.height)
                            
                        
                        Loader {
                            id: externalTile
                            anchors.fill: parent
                            anchors.margins: 1
                            asynchronous: true
                            z: 1
                            clip: true
                            
                            // Only exist when:
                            // 1) Start UI is visible
                            // 2) Tile is not launching
                            // 3) Live tile is enabled
                            // 4) QML path exists
                            active: WindowController.visible
                            && !tile.launching
                            && qmlEnabled
                            && tileQml
                            && tileQml.length > 0
                            
                            visible: active
                            
                            // Use file:/// prefix for absolute filesystem paths
                            source: active ? ("file:///" + tileQml) : ""
                            
                            onStatusChanged: {
                                if (status === Loader.Ready) {
                                    console.log("✅ Tile loaded successfully:", tileQml)
                                } else if (status === Loader.Error) {
                                    console.error("❌ Tile QML ERROR:", tileQml, "-", errorString())
                                    
                                    // Optional safety: auto-disable broken live tile
                                    // tileModel.setTileQmlEnabled(index, false)
                                }
                            }
                            
                        }
                        
                        
                        // transforms
                        transform: [
                            Rotation {
                                id: flipRotation
                                origin.x: tile.width / 2
                                origin.y: tile.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: 0
                            },
                            Rotation {
                                id: flipRotation2
                                origin.x: tile.width / 3
                                origin.y: tile.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: 0
                            },
                            Scale {
                                id: zoomScale
                                origin.x: tile.width / 2
                                origin.y: tile.height / 2
                                xScale: 1
                                yScale: 1
                            }
                        ]
                            
                        SequentialAnimation {
                            id: launchAnim
                            running: tile.launching
                            
                            onStarted: {
                                tile.border.width = 0
                            }
                                
                            ParallelAnimation {
                                id: launchAnim2
                                
                                // --- flip ---
                                NumberAnimation {
                                    target: flipRotation
                                    property: "angle"
                                    to: 180
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: flipiconRotation
                                    property: "angle"
                                    to: 180
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                                
                                // --- zoom ---
                                NumberAnimation {
                                    target: zoomScale
                                    property: "xScale"
                                    to: mainwindow.width / tile.width 
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: zoomScale
                                    property: "yScale"
                                    to: mainwindow.height / tile.height
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                                
                                NumberAnimation {
                                    target: zoomiconScale
                                    property: "xScale"
                                    to: (mainwindow.height / tile.height) / (mainwindow.width / tile.width)/2
                                    duration: 350
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: zoomiconScale
                                    property: "yScale"
                                    to: 1/2
                                    duration: 350
                                    easing.type: Easing.InOutQuad
                                }
                                
                                // --- move to center ---
                                NumberAnimation {
                                    target: tile
                                    property: "x"
                                    to: tile.finalX
                                    duration: 400
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: tile
                                    property: "y"
                                    to: tile.finalY
                                    duration: 400
                                    easing.type: Easing.InOutQuad
                                }
                            }
                            
                            // ✅ delay AFTER animation
                            PauseAnimation {
                                duration: 500
                            }
                            
                            ScriptAction {
                                script: {
                                    // Hide the window
                                    WindowController.hide()
                                    
                                    // Reset tile properties
                                    tile.launching = false
                                    container.anyTileLaunching = false
                                    tile.border.width = 1
                                    
                                    // Reset tile position to its model position
                                    tile.x = modelX
                                    tile.y = modelY
                                    
                                    // Reset transforms
                                    zoomScale.xScale = 1
                                    zoomScale.yScale = 1
                                    flipRotation.angle = 0
                                    
                                    zoomiconScale.xScale = 1
                                    zoomiconScale.yScale = 1
                                    flipiconRotation.angle = 0
                                }
                            }
                            
                        }
                        
                        //-----------------------------------------------------------
                        // Name
                        //-----------------------------------------------------------
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            text: tile.name
                            color: "white"
                            font.pointSize: tile.size === "small" ? 1 : 12
                            wrapMode: Text.Wrap
                            width: parent.width - 10
                            z: 2
                            visible: !tile.launching
                        }
                        
                        //-----------------------------------------------------------
                        // Icon
                        //-----------------------------------------------------------
                        Image {
                            id: tileicon
                            anchors.centerIn: parent
                            width: parent.height / 2
                            height: width
                            fillMode: Image.PreserveAspectFit
                            source: AppLauncher.resolveIcon(tile.icon)
                            sourceSize.width: 256
                            sourceSize.height: 256
                            // transforms
                            transform: [
                                Rotation {
                                    id: flipiconRotation
                                    origin.x: tileicon.width / 2
                                    origin.y: tileicon.height / 2
                                    axis { x: 0; y: 1; z: 0 }
                                    angle: 0
                                },
                                Scale {
                                    id: zoomiconScale
                                    origin.x: tileicon.width / 2
                                    origin.y: tileicon.height / 2
                                    xScale: 1
                                    yScale: 1
                                }
                            ]
                        }
                        
                        Image {
                            id: tileicon2
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            source: AppLauncher.resolveIcon(tile.icon)
                            sourceSize.width: 25
                            sourceSize.height: 25
                            z:2
                            visible: !tile.launching
                            && tile.qmlEnabled
                            
                        }
                        //-----------------------------------------------------------
                        // Dragging & Click
                        //-----------------------------------------------------------
                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            drag.target: tile

                            property bool dragging: false
                            onEntered: {
                                tile.hovered = true
                            }
                            onExited: {
                                tile.hovered = false
                            }

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    dragging = true

                            }

                            onReleased: {
                                dragging = false

                                var snappedX = Math.round(tile.x / container.halfGrid) * container.halfGrid
                                var snappedY = Math.round(tile.y / container.halfGrid) * container.halfGrid

                                snappedX = Math.max(0, Math.min(snappedX, container.contentWidth - tile.width))
                                snappedY = Math.max(0, snappedY)

                                tile.x = snappedX
                                tile.y = snappedY

                                tileModel.updateTilePosition(tile.index, tile.x, tile.y)
                            }

                            onClicked: function(mouse){
                                if (mouse.button === Qt.LeftButton) {
                                    tile.launch()
                                } else if (mouse.button === Qt.RightButton) {
                                    contextMenu.open()
                                }
                            }
                        }
                        
                        function recalculateTilePosition() {
                            var snappedX = Math.round(tile.x / container.halfGrid) * container.halfGrid
                            var snappedY = Math.round(tile.y / container.halfGrid) * container.halfGrid
                            
                            snappedX = Math.max(0, Math.min(snappedX, container.contentWidth - tile.width))
                            snappedY = Math.max(0, snappedY)
                            
                            tile.x = snappedX
                            tile.y = snappedY
                            
                            tileModel.updateTilePosition(tile.index, tile.x, tile.y)
                        }
                        
                        //-----------------------------------------------------------
                        // Right-click menu
                        //-----------------------------------------------------------
                        Menu {
                            id: contextMenu
                            
                            MenuItem { text: "Small";   onTriggered: tileModel.resizeTile(tile.index, "small") }
                            MenuItem { text: "Medium";  onTriggered: tileModel.resizeTile(tile.index, "medium") }
                            MenuItem { text: "Large";   onTriggered: tileModel.resizeTile(tile.index, "large") }
                            MenuItem { text: "XLarge";  onTriggered: tileModel.resizeTile(tile.index, "xlarge") }
                            
                            MenuSeparator {}
                            
                            MenuItem {
                                text: "Color"
                                onTriggered: {
                                    dialog.open()
                                    WindowController.hide()
                                }
                            }
                            
                            MenuItem {
                                text: "Reset Color"
                                enabled: tileColor && tileColor.length > 0
                                onTriggered: tileModel.resetTileColor(tile.index)
                            }
                            MenuSeparator {}
                            
                            MenuItem {
                                text: qmlEnabled ? "Disable Live Tile" : "Enable Live Tile"
                                onTriggered: tileModel.setTileQmlEnabled(tile.index, !qmlEnabled)
                            }
                            
                            
                            MenuSeparator {}
                            
                            MenuItem { text: "Remove"; onTriggered: tileModel.removeTile(tile.index) }
                        }
                        
                        
                        // --- APPEAR ANIMATION ---
                        property bool appeared: false
                        // property bool anyTileLaunching: false
                        opacity: 0.1
                        scale: 1
                        transformOrigin: Item.Left
                        
                        ParallelAnimation {
                            id: appearAnim
                            running: false
                            onStarted: container.clip = false
                            // onStopped: container.clip = !anyTileLaunching
                            
                            PropertyAnimation {
                                target: tile
                                property: "x"
                                from: tile.modelX+(mainwindow.width/3); to: tile.modelX
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                            
                            SequentialAnimation {
                                PropertyAnimation {
                                    target: tile
                                    property: "scale"
                                    from: 1; to: 0.97
                                    duration: 350
                                    easing.type: Easing.OutCubic
                                }
                                PropertyAnimation {
                                    target: tile
                                    property: "scale"
                                    from: 0.97; to: 1
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            
                            PropertyAnimation {
                                target: tile
                                property: "opacity"
                                from: 0.1; to: 1
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                            
                            SequentialAnimation {
                                NumberAnimation {
                                    target: flipRotation2
                                    property: "angle"
                                    to: 10
                                    duration: 300
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    target: flipRotation2
                                    property: "angle"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                            onStopped: {
                                recalculateTilePosition()
                            }
                            ScriptAction {
                                script: {
                                    // recalculateTilePosition()
                                }
                            }
                            
                        }
                        
                        Component.onCompleted: {
                            if (tileQml && tileQml.length > 0) {
                                tileModel.setTileQml(index, tileQml)
                            } else if (name && name.length > 0) {
                                tileModel.setTileQml(index, name)
                            }
                            
                            if (!appeared) {
                                appeared = true
                                appearAnim.start()
                            }
                        }
                        
                        
                        
                        Connections {
                            target: WindowController
                            
                            function onVisibleChanged(visible) {
                                if (visible) {
                                    tile.appeared = false
                                    appearAnim.start()
                                }
                            }
                        }
                        
                    }
                }
            }
            
        }
    }
    // shows all app in fullscreen rectangle.
    Rectangle {
        id: allapparea
        width: parent.width
        height: parent.height
        color: Win8Colors.Background
        y: parent.height
        
        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        
        Text {
            id: apps
            text: "Apps"
            font.pixelSize: 60
            color: "white"
            font.weight: Font.Thin
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 30
            anchors.leftMargin: 120
            anchors.topMargin: 50
        }
        Rectangle {
            id: allAppsButton2
            width: 50
            height: 50
            radius: width/2
            border.width: 2
            border.color: "white"
            color: "transparent"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 30
            anchors.leftMargin: 120
            
            Image {
                id: iconImg2
                anchors.centerIn: parent
                width: 40
                height: 40
                source: "icons/go-up-skip.svg"
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    onClicked: {
                        allapparea.y=allapparea.height
                        searchField.focus = false
                        appGridView.focus = false
                        container.focus = true
                        searchField.text = ""
                        categoryFilter.currentIndex = 0
                    }
                }
            }
            
        }
        //Searchfield searches for apps.
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 30
            anchors.leftMargin: 120
            anchors.topMargin: 50
            height: 50
            width: 350
            color: Win8Colors.Tile
            
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                spacing: 10
                
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    source: "icons/search.svg"
                    sourceSize.width: 30
                    sourceSize.height: 30
                }
                
                TextField {
                    id: searchField
                    width: 300
                    height: 50
                    placeholderText: "Search apps…"
                    color: "white"
                    background: null
                    placeholderTextColor: "#888888"
                    font.pointSize: 16
                    onTextChanged: {
                        appModel.search(text)
                        appGridView.currentIndex = 0   // ⭐ reset selection
                        categoryFilter.currentIndex = 0
                    }
                    
                    Keys.onTabPressed: {
                        appGridView.forceActiveFocus()
                    }
                    Keys.onPressed: function(event) {
                        switch (event.key) {
                            case Qt.Key_Down:
                                if (appGridView.count > 0) {
                                    appGridView.forceActiveFocus()
                                    appGridView.currentIndex = 0
                                    event.accepted = true
                                }
                                break
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                if (appGridView.count > 0) {
                                    // Launch the first app (currentIndex = 0)
                                    appGridView.currentIndex = 0
                                    var firstItem = appGridView.currentItem
                                    if (firstItem) {
                                        firstItem.launch()   // assuming your delegate has a launch() function
                                    }
                                    event.accepted = true
                                }
                                break
                            case Qt.Key_A:
                                // Check for Ctrl modifier
                                if (event.modifiers & Qt.ControlModifier) {
                                    allapparea.y=allapparea.height
                                    searchField.focus = false
                                    appGridView.focus = false
                                    container.focus = true
                                    event.accepted = true
                                }
                                break
                        }
                    }
                }
            }
            
        }
        ComboBox {
            id: categoryFilter
            anchors.top: apps.top
            anchors.left: apps.right
            anchors.topMargin: 10
            anchors.leftMargin: 120
            width: 300
            height: apps.height
            font.pixelSize: 40
            font.weight: Font.Thin
            model: ["All", "Utility", "Development", "Network", "Office", "AudioVideo", "Game", "System", "Graphics", "KDE", "Gnome"] // populate dynamically if needed
            currentIndex: 0
            
            background: Rectangle {
                color: "transparent"
                border.color: "transparent"
            }
            
            Keys.onTabPressed: {
                appGridView.forceActiveFocus()
            }
            
            onCurrentTextChanged: {
                if (currentText === "All")
                    appModel.setCategoryFilter("")
                    else
                        appModel.setCategoryFilter(currentText)
                        appGridView.currentIndex = 0
                        appGridView.focus = true
            }
        }
        
        Item {
            anchors.top: apps.bottom
            anchors.bottom: allAppsButton2.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 120
            anchors.topMargin: 30
            anchors.bottomMargin: 30
            width: parent.width - 120
            
            GridView {
                id: appGridView
                anchors.fill: parent
                model: appModel
                cellWidth: 400
                cellHeight: 80
                focus: false
                flow: GridView.TopToBottom
                // boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: true
                flickableDirection: Flickable.HorizontalFlick
                currentIndex: 0
                
                Behavior on contentX {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
                
                // index of currently launching delegate
                property int launchingIndex: -1
                
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: false
                    propagateComposedEvents: true
                    
                    onWheel: function(wheel) {
                        let isTouchpad = wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0
                        
                        // Touchpad vertical DOWN → go to bottom
                        if (isTouchpad && wheel.pixelDelta.y > 0) {
                            allapparea.y = allapparea.height
                            container.focus = true
                            searchField.text = ""
                            categoryFilter.currentIndex = 0
                        }
                            
                        // Horizontal scrolling
                        let delta = 0
                        if (isTouchpad) {
                            // Touchpad: horizontal ONLY
                            delta = -wheel.pixelDelta.x *10
                        } else {
                            // Mouse wheel: original behavior
                            delta = -(wheel.angleDelta.y + wheel.angleDelta.x)
                        }
                        
                        if (delta !== 0) {
                            let newX = appGridView.contentX + delta
                            newX = Math.max(0,
                                            Math.min(newX,
                                                     appGridView.contentWidth - appGridView.width))
                            appGridView.contentX = newX
                            wheel.accepted = true
                        }
                    }
                }
                
                Keys.onPressed: function(event) {
                    let columns = Math.floor(width / cellWidth)
                    if (columns < 1) columns = 1
                        let rows = Math.floor(height / cellHeight)
                        if (rows < 1) rows = 1
                        
                            // Alphanumeric key handling: focus searchField
                            let text = event.text
                            if (text.length === 1 && /[a-zA-Z0-9]/.test(text)) {
                            
                                // If searchField wasn't focused, this is the first keypress
                                let firstKey = !searchField.activeFocus
                                
                                searchField.forceActiveFocus()
                                
                                if (firstKey) {
                                    searchField.text = ""      // clear once
                                }
                                
                                searchField.text += text
                                searchField.cursorPosition = searchField.text.length
                                event.accepted = true
                                return
                            }
                            
                            switch (event.key) {
                                case Qt.Key_Backspace:
                                    // Empty search field
                                    searchField.text = ""
                                    searchField.cursorPosition = 0
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Down:
                                    // Move down 1 item but never exceed last index
                                    currentIndex = Math.min(currentIndex + 1, count - 1)
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Up:
                                    // Move up 1 item but never go below 0
                                    currentIndex = Math.max(currentIndex - 1, 0)
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Right:
                                    // Move right by “rows” but limit to last item
                                    let rightStep = Math.min(rows, count - 1 - currentIndex)
                                    currentIndex += rightStep
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Left:
                                    // Move left by “rows” but limit to first item
                                    let leftStep = Math.min(rows, currentIndex)
                                    currentIndex -= leftStep
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Tab:
                                    searchField.forceActiveFocus()
                                    event.accepted = true
                                    break
                                    
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    launchCurrent()
                                    event.accepted = true
                                    break
                                case Qt.Key_A:
                                    // Check for Ctrl modifier
                                    if (event.modifiers & Qt.ControlModifier) {
                                        allapparea.y=allapparea.height
                                        searchField.focus = false
                                        appGridView.focus = false
                                        container.focus = true
                                        event.accepted = true
                                    }
                                    break
                                case Qt.Key_PageUp:
                                    allapparea.y=allapparea.height
                                    searchField.focus = false
                                    appGridView.focus = false
                                    container.focus = true
                                    break
                                    
                                case Qt.Key_Menu:
                                case Qt.Key_F10:
                                    if (event.modifiers & Qt.ShiftModifier) {
                                        var item = appGridView.currentItem
                                        if (item) {
                                            item.openActionMenu()
                                        }
                                        event.accepted = true
                                    }
                                    break
                                case Qt.Key_F5:
                                    if (AppLauncher) {
                                        AppLauncher.refreshApplications()
                                        event.accepted = true
                                    }
                                    break
                            }
                }
                
                function launchCurrent() {
                    if (currentIndex < 0 || currentIndex >= count)
                        return
                        
                        appGridView.launchingIndex = currentIndex
                        
                        var item = appGridView.currentItem
                        if (!item) return
                            
                            item.launch()
                }
                
                delegate: Column {
                    id: apptilecol
                    width: appGridView.cellWidth - 100
                    spacing: 0
                    clip: false
                    
                    // 🔑 REQUIRED MODEL ROLES (Qt 6)
                    required property int index
                    required property string name
                    required property string icon
                    required property string command
                    required property string desktopFilePath
                    required property bool terminal
                    
                    function openActionMenu() {
                        AppLauncher.loadDesktopActions(desktopFilePath, actionModel)
                        actionMenu.popup(appRect)
                    }
                    
                    // opacity logic
                    opacity: appGridView.launchingIndex === -1
                    ? 1
                    : (index === appGridView.launchingIndex ? 1 : 0)
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                    
                    property bool launching: false
                    
                    function launch() {
                        launching = true
                        apptext.opacity = 0
                        AppLauncher.launchApp(command, terminal)
                        launchAnimAllapp.start()
                    }
                    
                    Rectangle {
                        id: appRect
                        width: parent.width - 10
                        height: 50
                        clip: apptilecol.launching ? false : true
                        color: appGridView.currentIndex === apptilecol.index ? "#0078D7" : "transparent"
                        // Behavior on color {
                        //     NumberAnimation {
                        //         duration: 100
                        //         easing.type: Easing.Linear
                        //     }
                        // }
                        // property bool hovered: false
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 10
                            
                            // ---------------------------------------------------------
                            // ANIMATED ICON TILE
                            // ---------------------------------------------------------
                            Rectangle {
                                id: allapptile
                                width: 40
                                height: 40
                                color: Win8Colors.Tile
                                transformOrigin: Item.Center
                                
                                transform: [
                                    Rotation {
                                        id: flipRot
                                        origin.x: allapptile.width / 2
                                        origin.y: allapptile.height / 2
                                        axis { x: 0; y: 1; z: 0 }
                                        angle: 0
                                    },
                                    Scale {
                                        id: zoomScal
                                        origin.x: allapptile.width / 2
                                        origin.y: allapptile.height / 2
                                        xScale: 1
                                        yScale: 1
                                    }
                                ]
                                
                                Image {
                                    anchors.centerIn: parent
                                    id: appIcon
                                    source: apptilecol.icon
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                    width: 32
                                    height: 32
                                    fillMode: Image.PreserveAspectFit
                                        
                                    transform: [
                                        Rotation {
                                            id: flipiconRot
                                            origin.x: appIcon.width / 2
                                            origin.y: appIcon.height / 2
                                            axis { x: 0; y: 1; z: 0 }
                                            angle: 0
                                        },
                                        Scale {
                                            id: zoomiconScal
                                            origin.x: appIcon.width / 2
                                            origin.y: appIcon.height / 2
                                            xScale: 1
                                            yScale: 1
                                        }
                                    ]
                                }
                            }
                                
                            Text {
                                id: apptext
                                anchors.verticalCenter: parent.verticalCenter
                                text: apptilecol.name
                                color: "white"
                                font.pointSize: 16
                                elide: Text.ElideRight
                            }
                        }
                        Menu {
                            id: actionMenu
                            MenuItem {
                                text: "Open"
                                icon.name: "system-run"   // or application-x-executable

                                onTriggered: {
                                    appGridView.launchingIndex = apptilecol.index
                                    AppLauncher.launchApp(apptilecol.command)
                                    launchAnimAllapp.start()
                                }
                            }
                            
                            MenuSeparator { }
                            Repeater {
                                model: actionModel
                                
                                MenuItem {
                                    required property string name
                                    required property string command
                                    
                                    text: name
                                    
                                    onTriggered: {
                                        apptilecol.launching = true
                                        appGridView.launchingIndex = index
                                        AppLauncher.launchApp(command, terminal)
                                        apptext.opacity = 0
                                        launchAnimAllapp.start()
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            
                            onEntered: {
                                appGridView.currentIndex = apptilecol.index
                            }
                            
                            property bool dragStarted: false
                            property point pressPos: Qt.point(0, 0)
                            
                            onPressed: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    dragStarted = false
                                    pressPos = Qt.point(mouse.x, mouse.y)
                                }
                            }
                            
                            onPositionChanged: (mouse) => {
                                // 🔒 DO NOT drag on hover
                                if (!(mouse.buttons & Qt.LeftButton))
                                    return
                                    
                                    if (dragStarted)
                                        return
                                        
                                        if (Math.hypot(mouse.x - pressPos.x,
                                            mouse.y - pressPos.y) > 10) {
                                            dragStarted = true
                                            
                                            // 🛡 Defer system drag
                                            Qt.callLater(() => {
                                                AppLauncher.startSystemDrag(
                                                    apptilecol.desktopFilePath,
                                                    appIcon
                                                )
                                            })
                                            }
                            }
                            
                            onReleased: dragStarted = false
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    appGridView.launchingIndex = apptilecol.index
                                    apptilecol.launching = true
                                    apptext.opacity = 0
                                    AppLauncher.launchApp(apptilecol.command, apptilecol.terminal)
                                    launchAnimAllapp.start()
                                }
                                
                                if (mouse.button === Qt.RightButton) {
                                    AppLauncher.loadDesktopActions(
                                        apptilecol.desktopFilePath,
                                        actionModel
                                    )
                                    actionMenu.popup()
                                }
                            }
                        }
                        
                    }
                    
                    // ------------------------------------------------------------
                    // LAUNCH ANIMATION (full screen)
                    // ------------------------------------------------------------
                    SequentialAnimation {
                        id: launchAnimAllapp
                        running: false
                        
                        onStarted: {
                            var winItem = mainwindow.contentItem
                            var c = allapptile.mapToItem(
                                winItem,
                                allapptile.width / 2,
                                allapptile.height / 2
                            )
                            
                            var centerX = winItem.width  / 2
                            var centerY = winItem.height / 2
                            
                            moveXAnim.to = allapptile.x + (centerX - c.x)
                            moveYAnim.to = allapptile.y + (centerY - c.y)
                        }
                        
                        onStopped: {
                            // Hide window
                            WindowController.hide()
                            
                            // Reset all transforms
                            flipRot.angle = 0
                            flipiconRot.angle = 0
                            
                            zoomScal.xScale = 1
                            zoomScal.yScale = 1
                            zoomiconScal.xScale = 1
                            zoomiconScal.yScale = 1
                            
                            // Reset position
                            allapptile.x = 0
                            allapptile.y = 0
                            
                            // Reset opacity and launching state
                            apptilecol.launching = false
                            appGridView.launchingIndex = -1
                            apptext.opacity = 1
                            
                            // close all app section
                            allapparea.y=allapparea.height
                            container.focus = true
                        }
                        
                        ParallelAnimation {
                            // flip
                            NumberAnimation {
                                target: flipRot
                                property: "angle"
                                to: 180
                                duration: 650
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: flipiconRot
                                property: "angle"
                                to: 180
                                duration: 650
                                easing.type: Easing.InOutQuad
                            }
                            
                            // scale
                            NumberAnimation {
                                target: zoomScal
                                property: "xScale"
                                to: mainwindow.width / allapptile.width
                                duration: 650
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: zoomScal
                                property: "yScale"
                                to: mainwindow.height / allapptile.height
                                duration: 650
                                easing.type: Easing.InOutCubic
                            }
                            
                            NumberAnimation {
                                target: zoomiconScal
                                property: "xScale"
                                to: (mainwindow.height / allapptile.height) / (mainwindow.width / allapptile.width) / 3.2
                                duration: 350
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: zoomiconScal
                                property: "yScale"
                                to: 1 / 3.2
                                duration: 350
                                easing.type: Easing.InOutCubic
                            }
                            
                            // move
                            NumberAnimation {
                                id: moveXAnim
                                target: allapptile
                                property: "x"
                                duration: 400
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                id: moveYAnim
                                target: allapptile
                                property: "y"
                                duration: 400
                                easing.type: Easing.InOutQuad
                            }
                        }
                        
                        PauseAnimation { duration: 500 }
                    }
                }
            }
        }
        
        DropArea {
            id: backgroundDropArea
            width: mainwindow.width
            height: mainwindow.height
            onEntered: allapparea.y=allapparea.height
        }
    }
}
