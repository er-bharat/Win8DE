import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs 6.4

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
                        checked: currentPage === 0
                        onClicked: currentPage = 0
                    }

                    Button {
                        text: "Colors"
                        width: parent.width
                        checkable: true
                        checked: currentPage === 1
                        onClicked: currentPage = 1
                    }

                    Button {
                        text: "Hot Corners"
                        width: parent.width
                        checkable: true
                        checked: currentPage === 2
                        onClicked: currentPage = 2
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
                currentIndex: currentPage

                // ==================================================
                // ================= Wallpaper Page =================
                // ==================================================
                Item {
                    anchors.fill: parent

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
                                    width: parent.width / 3 - 20
                                    spacing: 8

                                    Text {
                                        text: modelData
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
                                            border.width: selectedWallpaperType === modelData ? 4 : 1
                                            border.color: selectedWallpaperType === modelData ? "dodgerblue" : "#666"
                                        }

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            fillMode: Image.PreserveAspectCrop
                                            source: modelData === "Desktop"
                                            ? toUrl(SettingsManager.desktopWallpaper)
                                            : modelData === "Lockscreen"
                                            ? toUrl(SettingsManager.lockscreenWallpaper)
                                            : toUrl(SettingsManager.startWallpaper)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: selectedWallpaperType = modelData
                                            onDoubleClicked: {
                                                let file = SettingsManager.openWallpaperFileDialog()
                                                if (file) SettingsManager.setWallpaper(modelData, file)
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
                                let folder = SettingsManager.openWallpaperFolderDialog(currentFolder)
                                if (folder) {
                                    currentFolder = folder
                                    folderImages = SettingsManager.listImagesInFolder(folder)
                                }
                            }
                        }

                        GridView {
                            width: parent.width
                            height: parent.height-wallview.height-folderbtn.height-40
                            cellWidth: 200
                            cellHeight: 114
                            model: folderImages
                            clip: true

                            delegate: Rectangle {
                                width: 200
                                height: 114
                                border.width: 0

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5   // ✅ margin inside cell
                                    color: "transparent"

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        fillMode: Image.PreserveAspectFit
                                        source: toUrl(modelData)
                                        sourceSize.width: 200     // load smaller width
                                        sourceSize.height: 200    // load smaller height

                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (selectedWallpaperType)
                                            SettingsManager.setWallpaper(selectedWallpaperType, modelData)
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
                    anchors.fill: parent
                    anchors.margins: 40

                    Column {
                        anchors.margins: 40
                        spacing: 20

                        Repeater {
                            model: ["Background", "Tile", "TileHighlight"]

                            delegate: Row {
                                spacing: 10

                                Text { text: modelData; width: 120 }

                                Rectangle {
                                    id: preview
                                    width: 50
                                    height: 25
                                    border.width: 1

                                    Component.onCompleted: {
                                        color = SettingsManager.getColor(modelData) || "white"
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
                                            SettingsManager.setColor(modelData, selectedColor)
                                        }
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
                    anchors.fill: parent
                    anchors.margins: 40

                    Column {
                        anchors.fill: parent
                        spacing: 20
                        anchors.margins: 20

                        Repeater {
                            model: [
                                {name: "TopLeft", value: SettingsManager.topLeftCorner},
                                {name: "TopRight", value: SettingsManager.topRightCorner},
                                {name: "BottomLeft", value: SettingsManager.bottomLeftCorner},
                                {name: "BottomRight", value: SettingsManager.bottomRightCorner}
                            ]

                            delegate: Row {
                                spacing: 10
                                width: parent.width

                                Text {
                                    text: modelData.name
                                    width: 120
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                TextField {
                                    id: cmdField
                                    text: modelData.value
                                    width: parent.width - 140
                                    placeholderText: "Enter command to run on hover"

                                    onEditingFinished: {
                                        // Update SettingsManager hot corner property dynamically
                                        if (modelData.name === "TopLeft") SettingsManager.topLeftCorner = text
                                            else if (modelData.name === "TopRight") SettingsManager.topRightCorner = text
                                                else if (modelData.name === "BottomLeft") SettingsManager.bottomLeftCorner = text
                                                    else if (modelData.name === "BottomRight") SettingsManager.bottomRightCorner = text
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
