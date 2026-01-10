import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs 6.4
pragma ComponentBehavior: Bound
ApplicationWindow {
    id: window
    visible: true
    visibility: Window.Maximized
    width: 1000
    height: 1000
    title: "Win8Settings"

    property int currentPage: 0   // 0 = Wallpaper, 1 = Colors

    property string selectedWallpaperType: ""
    property string selectedWallpaperPath: ""
    property string currentFolder: SettingsManager.lastWallpaperFolder
    property var folderImages: []

    Component.onCompleted: {
        if (currentFolder !== "") {
            folderImages = SettingsManager.listImagesInFolder(currentFolder)
        }
    }

    function toUrl(p) {
        if (!p) return ""
            if (p.startsWith("file://")) return p
                if (p.startsWith("/")) return "file://" + p
                    return p
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // ================= Sidebar =================
        Rectangle {
            id: sidebar
            width: parent.width / 3
            height: parent.height
            color: "#1e1e1e"

            Column {
                id: sidebarlayout
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: mainTitle
                    width: parent.width
                    height: parent.height/4
                    Text {
                        anchors.centerIn: parent
                        text: "PC Settings"
                        font.pixelSize: 40
                    }
                }
                Column {
                    // anchors.fill: parent
                    width: parent.width
                    height: parent.height*3/4
                    anchors.margins: 20
                    spacing: 10

                    Button {
                        text: "Wallpaper"
                        width: parent.width
                        checkable: true
                        checked: window.currentPage === 0
                        onClicked: window.currentPage = 0
                    }

                    Button {
                        text: "Colors"
                        width: parent.width
                        checkable: true
                        checked: window.currentPage === 1
                        onClicked: window.currentPage = 1
                    }

                    Button {
                        text: "Hot Corners"
                        width: parent.width
                        checkable: true
                        checked: window.currentPage === 2
                        onClicked: window.currentPage = 2
                    }

                }
            }


        }

        // ================= Main Content =================
        Rectangle {
            id: maincontent
            width: parent.width * 2 / 3
            height: parent.height
            color: "#f0f0f0"

            StackLayout {
                anchors.fill: parent
                currentIndex: window.currentPage

                // ==================================================
                // ================= Wallpaper Page =================
                // ==================================================
                Item {
                    Layout.alignment: Qt.AlignLeft
                    Column {
                        anchors.fill: parent
                        spacing: 20
                        anchors.margins: 20

                        Row {
                            id: wallview
                            width: parent.width
                            spacing: 20

                            Repeater {
                                model: ["Desktop", "Lockscreen", "Start"]

                                delegate: Column {
                                    id: walltype
                                    width: parent.width / 3 - 20
                                    spacing: 8

                                    required property string modelData

                                    Text {
                                        text: walltype.modelData
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        width: parent.width
                                    }

                                    Item {
                                        width: parent.width
                                        height: width * 9 / 16
                                        clip: true

                                        Rectangle {
                                            anchors.fill: parent
                                            border.width: window.selectedWallpaperType === walltype.modelData ? 4 : 1
                                            border.color: window.selectedWallpaperType === walltype.modelData ? "dodgerblue" : "#666"
                                        }

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            fillMode: Image.PreserveAspectCrop
                                            source: walltype.modelData === "Desktop"
                                            ? toUrl(SettingsManager.desktopWallpaper)
                                            : walltype.modelData === "Lockscreen"
                                            ? toUrl(SettingsManager.lockscreenWallpaper)
                                            : toUrl(SettingsManager.startWallpaper)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: window.selectedWallpaperType = walltype.modelData
                                            onDoubleClicked: {
                                                let file = SettingsManager.openWallpaperFileDialog()
                                                if (file) SettingsManager.setWallpaper(walltype.modelData, file)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            id: folderbtn
                            text: "Select Wallpaper Folder"
                            onClicked: {
                                let folder = SettingsManager.openWallpaperFolderDialog(window.currentFolder)
                                if (folder) {
                                    window.currentFolder = folder
                                    window.folderImages = SettingsManager.listImagesInFolder(folder)
                                }
                            }
                        }

                        GridView {
                            width: parent.width
                            height: parent.height-wallview.height-folderbtn.height-40
                            cellWidth: 200
                            cellHeight: 114
                            model: window.folderImages
                            clip: true

                            delegate: Rectangle {
                                id: wallpreview
                                width: 200
                                height: 114
                                border.width: 0

                                required property string modelData

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5   // ✅ margin inside cell
                                    color: "transparent"

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        fillMode: Image.PreserveAspectFit
                                        source: toUrl(wallpreview.modelData)
                                        // sourceSize.width: 200     // load smaller width
                                        // sourceSize.height: 200    // load smaller height

                                        asynchronous: true        // ✅ BIG WIN
                                        cache: true               // ✅ reuse decoded image
                                        mipmap: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (window.selectedWallpaperType)
                                            SettingsManager.setWallpaper(window.selectedWallpaperType, wallpreview.modelData)
                                    }
                                }
                            }
                        }

                    }
                }

                // ==================================================
                // ================= Colors Page ====================
                // ==================================================
                Item {
                    Layout.alignment: Qt.AlignLeft

                    Item {
                        anchors.fill:parent
                        Column {
                            padding: 20
                            spacing: 20

                            Repeater {
                                model: ["Background", "Tile", "TileHighlight"]

                                delegate: Row {
                                    id: colortype
                                    spacing: 10

                                    required property string modelData

                                    Text { 
                                        text: colortype.modelData
                                        width: 120 
                                        
                                    }

                                    Rectangle {
                                        id: preview
                                        width: 50
                                        height: 25
                                        border.width: 1

                                        Component.onCompleted: {
                                            color = SettingsManager.getColor(colortype.modelData) || "white"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: dialog.open()
                                        }

                                        ColorDialog {
                                            id: dialog
                                            selectedColor: preview.color
                                            onAccepted: {
                                                preview.color = selectedColor
                                                SettingsManager.setColor(colortype.modelData, selectedColor)
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: dialog.selectedColor
                                    }
                                }
                            }
                        }
                    }
                }

                // Add this after your Colors Page in StackLayout
                // ==================================================
                // ================= Hot Corners Page =================
                // ==================================================
                Item {
                    Layout.alignment: Qt.AlignLeft

                    Column {
                        anchors.fill: parent
                        spacing: 20
                        padding: 20

                        Repeater {
                            model: [
                                {name: "TopLeft", value: SettingsManager.topLeftCorner},
                                {name: "TopRight", value: SettingsManager.topRightCorner},
                                {name: "BottomLeft", value: SettingsManager.bottomLeftCorner},
                                {name: "BottomRight", value: SettingsManager.bottomRightCorner}
                            ]

                            delegate: Row {
                                id: cornertype
                                spacing: 10
                                width: parent.width

                                required property string modelData
                                required property string name
                                required property string value

                                Text {
                                    text: cornertype.name
                                    width: 120
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                TextField {
                                    id: cmdField
                                    text: cornertype.value
                                    width: parent.width - 140
                                    placeholderText: "Enter command to run on hover"

                                    onEditingFinished: {
                                        // Update SettingsManager hot corner property dynamically
                                        if (cornertype.name === "TopLeft") SettingsManager.topLeftCorner = text
                                            else if (cornertype.name === "TopRight") SettingsManager.topRightCorner = text
                                                else if (cornertype.name === "BottomLeft") SettingsManager.bottomLeftCorner = text
                                                    else if (cornertype.name === "BottomRight") SettingsManager.bottomRightCorner = text
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
