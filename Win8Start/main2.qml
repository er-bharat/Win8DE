import QtQuick
import QtQuick.Controls
// import QtQuick.Layouts

ApplicationWindow {

    id: mainwindow
    visible: false
    width: screen.width
    height: screen.height
    title: "Linux Start Menu Clone"
    color: "#180052"

    Image {
        id: background
        anchors.fill: parent
        source: startWallpaper
        fillMode: Image.PreserveAspectCrop
    }

    MouseArea {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        acceptedButtons: Qt.RightButton | Qt.LeftButton

        onClicked: (mouse)=>{
            WindowController.hide()
        }
    }


    DropArea {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        z: 0
        onEntered: {
            mainwindow.close()
        }
    }

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

        // Battery fill (with rounded corners)
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

    Rectangle {
        id: userCard
        width: 150
        height: 50
        color: "transparent"
        radius: 12
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
                color: "transparent"
                Image {
                    id: userIcon
                    source: "icons/peoplew.png"
                    width: 48
                    height: 48
                    fillMode: Image.PreserveAspectFit
                }
                Image {
                    id: userIcon2
                    source: "file:///var/lib/AccountsService/icons/" + AppLauncher.getCurrentUser()
                    width: 48
                    height: 48
                    fillMode: Image.PreserveAspectFit
                }
            }
        }

        Menu {
            id: powerMenu

            MenuItem {
                text: "Shutdown"
                icon.source: "/icons/system-shutdown-symbolic.svg"
                onTriggered: powerControl.shutdown()
            }

            MenuItem {
                text: "Reboot"
                icon.source: "/icons/view-refresh-symbolic.svg"
                onTriggered: powerControl.reboot()
            }

            MenuItem {
                text: "Suspend"
                icon.source: "/icons/system-run.svg"
                onTriggered: powerControl.suspend()
            }

            MenuItem {
                text: "Logout"
                icon.source: "/icons/system-log-out.svg"
                onTriggered: powerControl.logout()
            }

            MenuItem {
                text: "Settings"
                icon.source: "/icons/emblem-system-symbolic.svg"
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
            source: "go-down-skip.svg"
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

            onClicked: {
                allapparea.y = 0
                appGridView.focus = true
                refreshTimer.start()
                // searchField.focus = true
            }
        }

    }


    Rectangle {
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
        // height: parent.height*0.7
        color: "transparent"

        Flickable {
            id: container
            width: parent.width
            height: parent.height
            contentWidth: parent.width * 2
            contentHeight: parent.height
            property bool anyTileLaunching: false
            clip: !anyTileLaunching

            focus: true                       // >>> KEYBOARD NAVIGATION <<<
            activeFocusOnTab: true            // >>> KEYBOARD NAVIGATION <<<



            property int gridSize: tilearea.height/5
            property int halfGrid: gridSize / 2
            property int cols: Math.floor(width / halfGrid)

            // >>> KEYBOARD NAVIGATION <<<
            property int focusedIndex: -1

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


            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton    // ensures it doesn’t block clicks or drags
                hoverEnabled: false
                propagateComposedEvents: true

                onWheel: function(wheel) {
                    // desired movement
                    let delta = -(wheel.angleDelta.y + wheel.angleDelta.x)

                    // apply with brakes (clamping)
                    let newX = container.contentX + delta

                    // clamp to prevent overscroll
                    newX = Math.max(0, Math.min(newX, container.contentWidth - container.width))

                    container.contentX = newX

                    wheel.accepted = true
                }

            }

            DropArea {
                anchors.fill: parent
                onDropped: (drop) => {
                    if (drop.hasUrls) {
                        for (let i = 0; i < drop.urls.length; ++i) {
                            const url = drop.urls[i];
                            if (url.toString().endsWith(".desktop")) {
                                const localPath = url.toString().replace("file://", "");
                                tileModel.addTileFromDesktopFile(localPath, drop.x, drop.y);
                            }
                        }
                    }
                }
            }

            Repeater {
                id: tileRepeater
                model: tileModel

                Rectangle {
                    id: tile
                    z: (launching || dragArea.dragging) ? 200 : 0

                    property string appCommand: model.command


                    // --- Size handling ---
                    property string size: model.size

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

                    x: model.x
                    y: model.y

                    property bool hovered: false

                    color: dragArea.dragging || container.focusedIndex === model.index || hovered ? Win8Colors.TileHighlight : Win8Colors.Tile
                    border.width: 1
                    border.color: container.focusedIndex === model.index || hovered
                    ? "white"
                    : Qt.rgba(1,1,1,0.2)


                    function launch() {
                        if (tile.launching)
                            return

                            tile.launching = true
                            container.anyTileLaunching = true
                            AppLauncher.launchApp(tile.appCommand)
                    }


                    //-----------------------------------------------------------
                    // LAUNCH ANIMATION PROPERTIES
                    //-----------------------------------------------------------
                    property bool launching: false

                    // fixed center target
                    property real finalX: container.contentX + container.width  / 2 - width  / 2 - 60
                    property real finalY: container.contentY + container.height / 2 - height / 2 -(start.height-allAppsButton.height)

                    // transforms
                    transform: [
                        Rotation {
                            id: flipRotation
                            origin.x: tile.width / 2
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
                                to: screen.width / tile.width * 1.05
                                duration: 650
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: zoomScale
                                property: "yScale"
                                to: screen.height / tile.height * 1.05
                                duration: 650
                                easing.type: Easing.InOutQuad
                            }

                            NumberAnimation {
                                target: zoomiconScale
                                property: "xScale"
                                to: (screen.height / tile.height) / (screen.width / tile.width)/2
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

                                // Reset tile position to its model position
                                tile.x = model.x
                                tile.y = model.y

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
                        text: model.name
                        color: "white"
                        font.pointSize: size === "small" ? 1 : 12
                        wrapMode: Text.Wrap
                        width: parent.width - 10
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
                        source: AppLauncher.resolveIcon(model.icon)
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

                        onPressed: {
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

                            tileModel.updateTilePosition(model.index, tile.x, tile.y)
                        }

                        onClicked: {
                            if (mouse.button === Qt.LeftButton) {
                                tile.launch()
                            } else if (mouse.button === Qt.RightButton) {
                                contextMenu.open()
                            }
                        }
                    }

                    //-----------------------------------------------------------
                    // Right-click menu
                    //-----------------------------------------------------------
                    Menu {
                        id: contextMenu
                        MenuItem { text: "Small";   onTriggered: tileModel.resizeTile(model.index, "small") }
                        MenuItem { text: "Medium";  onTriggered: tileModel.resizeTile(model.index, "medium") }
                        MenuItem { text: "Large";   onTriggered: tileModel.resizeTile(model.index, "large") }
                        MenuItem { text: "XLarge";  onTriggered: tileModel.resizeTile(model.index, "xlarge") }
                        MenuSeparator {}
                        MenuItem { text: "Remove";  onTriggered: tileModel.removeTile(model.index) }
                    }

                    // --- APPEAR ANIMATION ---
                    property bool appeared: false
                    // property bool anyTileLaunching: false
                    opacity: 0.2
                    scale: 0.6
                    transformOrigin: Item.Left


                    ParallelAnimation {
                        id: appearAnim
                        running: false
                        onStarted: container.clip = false
                        // onStopped: container.clip = !anyTileLaunching

                        PropertyAnimation {
                            target: tile
                            property: "x"
                            from: container.width/4; to: model.x
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            // 1. move upward (bounce start)
                            PropertyAnimation {
                                target: tile
                                property: "y"
                                from: model.y
                                to: model.y - 10
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                            // 2. fall down past the final position (overshoot)
                            PropertyAnimation {
                                target: tile
                                property: "y"
                                from: model.y - 10
                                to: model.y + 10      // overshoot 30px down
                                duration: 130
                                easing.type: Easing.InCubic
                            }

                            // 3. settle back to the final position (real bounce)
                            PropertyAnimation {
                                target: tile
                                property: "y"
                                from: model.y + 10
                                to: model.y
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }


                        PropertyAnimation {
                            target: tile
                            property: "scale"
                            from: 0.6; to: 1
                            duration: 700
                            easing.type: Easing.OutCubic
                        }

                        PropertyAnimation {
                            target: tile
                            property: "opacity"
                            from: 0.2; to: 1
                            duration: 800
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
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
                source: "go-up-skip.svg"
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
                    }
                }
            }

        }
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 30
            anchors.leftMargin: 120
            anchors.topMargin: 50
            height: 50
            width: 500
            color: Win8Colors.Tile

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 8
                placeholderText: "Search apps…"
                color: "white"
                background: null
                placeholderTextColor: "#888888"
                font.pointSize: 16
                onTextChanged: {
                    appModel.search(text)
                    appGridView.currentIndex = 0   // ⭐ reset selection
                }

                Keys.onTabPressed: {
                    appGridView.forceActiveFocus()
                    event.accepted = true
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

        Rectangle {
            anchors.top: apps.bottom
            anchors.bottom: allAppsButton2.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 120
            anchors.topMargin: 30
            anchors.bottomMargin: 30
            width: parent.width - 120
            height: parent.height*0.7
            color: "transparent"



            GridView {
                id: appGridView
                anchors.fill: parent
                model: appModel
                cellWidth: 400
                cellHeight: 80
                focus: false
                flow: GridView.TopToBottom
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: true
                // keyNavigationNavigationWraps: true
                highlightFollowsCurrentItem: true
                flickableDirection: Flickable.HorizontalFlick
                currentIndex: 0

                // 🔹 index of currently launching delegate
                property int launchingIndex: -1

                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: false
                    propagateComposedEvents: true

                    onWheel: function(wheel) {
                        let delta = -(wheel.angleDelta.y + wheel.angleDelta.x)
                        let newX = appGridView.contentX + delta
                        newX = Math.max(0,
                                        Math.min(newX, appGridView.contentWidth - appGridView.width))
                        appGridView.contentX = newX
                        wheel.accepted = true
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
                                searchField.forceActiveFocus()
                                searchField.text += text
                                searchField.cursorPosition = searchField.text.length
                                event.accepted = true
                                return
                            }

                            switch (event.key) {
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
                    width: appGridView.cellWidth - 100
                    spacing: 0
                    clip: false

                    property string desktopFilePath: model.desktopFilePath

                    function openActionMenu() {
                        AppLauncher.loadDesktopActions(desktopFilePath, actionModel)
                        actionMenu.popup(appRect)
                    }


                    // 🔹 opacity logic
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
                        AppLauncher.launchApp(model.command)
                        launchAnimAllapp.start()
                    }

                    Rectangle {
                        id: appRect
                        width: parent.width - 10
                        height: 50
                        color: (appGridView.currentIndex === index || hovered)
                        ? "#0078D7"
                        : "transparent"

                        property bool hovered: false

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
                                    source: icon
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
                                text: model.name
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
                                    appGridView.launchingIndex = index
                                    AppLauncher.launchApp(model.command)
                                    launchAnimAllapp.start()
                                }
                            }

                            MenuSeparator { }
                            Repeater {
                                model: actionModel

                                MenuItem {
                                    text: model.name
                                    icon.source: model.icon

                                    onTriggered: {
                                        launching = true
                                        // appGridView.launchingIndex = index
                                        AppLauncher.launchApp(model.command)
                                        launchAnimAllapp.start()
                                    }
                                }
                            }
                        }


                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: appRect.hovered = true
                            onExited: appRect.hovered = false
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            property bool dragStarted: false
                            property point pressPos

                            onPressed: function(mouse) {
                                dragStarted = false
                                pressPos = Qt.point(mouse.x, mouse.y)
                            }

                            onPositionChanged: function(mouse) {
                                if (!dragStarted) {
                                    let dx = mouse.x - pressPos.x
                                    let dy = mouse.y - pressPos.y
                                    if (Math.sqrt(dx*dx + dy*dy) > 10) {
                                        dragStarted = true
                                        AppLauncher.startSystemDrag(
                                            model.desktopFilePath, appIcon)
                                    }
                                }
                            }

                            onReleased: dragStarted = false

                            onClicked: function(mouse) {

                                // LEFT CLICK → normal launch
                                if (mouse.button === Qt.LeftButton) {
                                    appGridView.launchingIndex = index
                                    launching = true
                                    apptext.opacity = 0
                                    AppLauncher.launchApp(model.command)
                                    launchAnimAllapp.start()
                                }

                                // RIGHT CLICK → open desktop actions menu
                                if (mouse.button === Qt.RightButton) {
                                    AppLauncher.loadDesktopActions(
                                        model.desktopFilePath,
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
                            launching = false
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
                                to: screen.width / allapptile.width
                                duration: 650
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: zoomScal
                                property: "yScale"
                                to: screen.height / allapptile.height
                                duration: 650
                                easing.type: Easing.InOutCubic
                            }

                            NumberAnimation {
                                target: zoomiconScal
                                property: "xScale"
                                to: (screen.height / allapptile.height) / (screen.width / allapptile.width) / 3.2
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
            width: screen.width
            height: screen.height
            onEntered: allapparea.y=allapparea.height
        }

    }

}
