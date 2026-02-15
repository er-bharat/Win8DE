import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
	visible: true
	width: 360
	height: 600
	color: "#1f1f1f"
	
	ColumnLayout {
		anchors.fill: parent
		
		// ================= HEADER =================
		Rectangle {
			height: 70
			color: "#0078d7"
			Layout.fillWidth: true
			
			RowLayout {
				anchors.fill: parent
				anchors.margins: 15
				
				Label {
					text: "Wi-Fi"
					color: "white"
					font.pixelSize: 26
					Layout.fillWidth: true
				}
				
				Switch {
					checked: wifiModel.wifiEnabled
					onToggled:
					wifiModel.wifiEnabled = checked
				}
			}
		}
		
		// ================= WIFI LIST =================
		ListView {
			model: wifiModel
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			
			delegate: Rectangle {
				height: 72
				width: ListView.view.width
				
				property bool hovered: false
				
				color: connected
				? "#0e639c"
				: hovered
				? "#383838"
				: "#2b2b2b"
				
				Behavior on color {
					ColorAnimation { duration: 120 }
				}
				
				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					
					onEntered: parent.hovered = true
					onExited: parent.hovered = false
					
					onClicked: {
						wifiModel.toggleConnection(ssid, connected)
					}
				}
				
				RowLayout {
					anchors.fill: parent
					anchors.margins: 12
					spacing: 12
					
					// ⭐ SIGNAL BARS (LEFT)
					// ⭐ SIGNAL BARS (REAL WIFI SHAPE)
					Item {
						id: signalRoot
						width: 26
						height: 26
						
						property int strengthValue:
						Number(strength.toString().replace("%","")) || 0
						
						Row {
							anchors.bottom: parent.bottom
							spacing: 2
							
							Repeater {
								model: 5
								
								Rectangle {
									width: 4
									height: 4 + (index * 4)
									radius: 2
									anchors.bottom: parent.bottom
									
									color: signalRoot.strengthValue > index * 20
									? "#ebebeb"
									: "#555555"
								}
							}
						}
					}
					
					
					// ⭐ TEXT (RIGHT)
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 2
						
						
						Label {
							text: ssid
							color: "white"
							font.pixelSize: 18
							elide: Text.ElideRight
						}
						
						// ⭐ CLEAN STATUS LINE
						Label {
							text:
							(security || "Open") + " • " +
							(band || "") +
							(band ? " • " : "") +
							strength
							
							color: "#bbbbbb"
							font.pixelSize: 13
						}
					}
				}
			}
			
		}
		
		// ================= SCAN =================
		Button {
			text: "Scan"
			Layout.fillWidth: true
			onClicked: wifiModel.refreshWifi()
		}
	}
}
