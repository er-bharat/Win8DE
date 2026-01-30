import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: liveTile
    anchors.fill: parent
    
    property var holidays: []
    property date simulatedDate: new Date(/*2026, 0, 14*/)
    property string mode: "rectangle" // "rectangle" or "square"
    
    // Background
    Rectangle {
        id: back
        anchors.fill: parent
        // Background color property
        property color bgColor: "#3498db"  // default blue
        
        // Gradient background using bgColor
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.darker(back.bgColor, 1.2) } // left darker
            GradientStop { position: 1.0; color: Qt.lighter(back.bgColor, 1.2) } // right lighter
        }
    }
    
    // Holiday text (left side in rectangle mode, full width in square mode)
    Text {
        id: holidayText
        text: "Loading..."
        color: "white"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        wrapMode: Text.Wrap
        font.pixelSize: 25
        horizontalAlignment: Text.AlignLeft
        
        anchors.leftMargin: 30
        anchors.topMargin: parent.height / 4
        
        anchors.right: (mode === "rectangle") ? dateRect.left : parent.right
        anchors.rightMargin: (mode === "rectangle") ? 10 : 10
    }
    
    // Right rectangle for date & day (only rectangle mode or square mode adjustment)
    Rectangle {
        id: dateRect
        width: (mode === "rectangle") ? parent.width / 3 : parent.width / 2
        height: parent.height
        anchors.top: parent.top
        anchors.right: parent.right
        color: "transparent"
        
        // Day number
        Text {
            id: dateText
            text: ""
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            font.weight: Font.Thin
            lineHeight: 0.9
            font.pixelSize: Math.max(parent.width / 1.5, 24) // bigger in square mode
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Weekday name
        Text {
            id: dayText
            text: ""
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dateText.bottom
            font.pixelSize: Math.max(dateText.width / 6, 12)
            font.weight: Font.Thin
            horizontalAlignment: Text.AlignHCenter
        }
        
        visible: mode !== "square" || true // keep visible in both modes, adjust size
    }
    
    function normalizeFileUrl(u) {
        var s = u.toString();   // convert QUrl → string
        
        if (s.indexOf("file:///") === 0)
            return s;
        
        if (s.indexOf("file://") === 0) {
            var path = s.substring("file://".length);
            
            if (path.charAt(0) !== "/")
                path = "/" + path;
            
            return "file://" + path;   // results in file:///home/...
        }
        
        return s;
    }
    
    
    Component.onCompleted: {
        // 1. Resolve path relative to THIS .qml file
        // Assumes indian_holidays.json is in the same folder as this QML file
        var relativePath = Qt.resolvedUrl("indian_holidays.json");
        var fixedUrl = normalizeFileUrl(relativePath);
        var fh = new XMLHttpRequest();
        fh.open("GET", fixedUrl, false); // Use the resolved relative path
        fh.send();
        
        if (fh.status === 200 || fh.status === 0) {
            holidays = JSON.parse(fh.responseText.replace(/[\r\n]+/g, ""));
        } else {
            holidayText.text = "Failed to load holiday data";
            return;
        }
        
        updateHoliday();
    }
    
    
    function updateHoliday() {
        var today = simulatedDate || new Date();
        
        var todayStr = today.getFullYear().toString() +
        ("0" + (today.getMonth() + 1)).slice(-2) +
        ("0" + today.getDate()).slice(-2);
        
        var names = [];
        
        for (var i = 0; i < holidays.length; i++) {
            if (holidays[i].date === todayStr) {
                names.push(holidays[i].name);
            }
        }
        
        if (names.length > 0) {
            holidayText.text = names.join("\n"); // show all holidays
        } else {
            holidayText.text = "Nothing Today";
        }
        
        dateText.text = today.getDate().toString();
        
        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        dayText.text = days[today.getDay()];
    }
    
}
