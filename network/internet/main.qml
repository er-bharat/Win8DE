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
		
		ListView {
			model: wifiModel
			Layout.fillWidth: true
			Layout.fillHeight: true
			
			delegate: Rectangle {
				height: 72
				width: parent.width
				color: connected ? "#0e639c" : "#2b2b2b"
				
				RowLayout {
					anchors.fill: parent
					anchors.margins: 10
					
					ColumnLayout {
						Layout.fillWidth: true
						
						Label {
							text: ssid
							color: "white"
							font.pixelSize: 18
						}
						
						Label {
							text: connected
							? "Connected"
							: security + " • " + strength
							
							color: "#bbbbbb"
							font.pixelSize: 13
						}
					}
					
					Button {
						text: connected ? "Disconnect" : "Connect"
						
						onClicked:
						wifiModel.toggleConnection(
							ssid,
							connected
						)
					}
				}
			}
		}
		
		Button {
			text: "Scan"
			Layout.fillWidth: true
			onClicked: wifiModel.refreshWifi()
		}
	}
}
