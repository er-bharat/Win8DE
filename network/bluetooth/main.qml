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
					text: "Bluetooth"
					color: "white"
					font.pixelSize: 26
					Layout.fillWidth: true
				}
				
				Switch {
					checked: btModel.bluetoothEnabled
					onToggled: btModel.setBluetoothEnabled(checked)
				}
			}
		}
		
		// ================= DEVICE LIST =================
		ListView {
			model: btModel
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
					
					onClicked: btModel.toggleConnection(address, connected)
				}
				
				RowLayout {
					anchors.fill: parent
					anchors.margins: 12
					spacing: 12
					
					// ⭐ CONNECTION STATUS DOT
					Rectangle {
						width: 16
						height: 16
						radius: 8
						color: connected
						? "#00ff00"
						: paired
						? "#ffff00"
						: "#555555"
					}
					
					// ⭐ DEVICE NAME & ADDRESS
					ColumnLayout {
						Layout.fillWidth: true
						spacing: 2
						
						Label {
							text: name
							color: "white"
							font.pixelSize: 18
							elide: Text.ElideRight
						}
						
						Label {
							text: address + (paired ? " • Paired" : "")
							color: "#bbbbbb"
							font.pixelSize: 13
						}
					}
				}
			}
		}
		
		// ================= SCAN =================
		Button {
			Layout.fillWidth: true
			onClicked: btModel.refreshDevices()
			background: Rectangle {
				color: "#55557c"
				radius: 0
			}
			contentItem: Text {
				text: "Scan"
				color: "#ffffff"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				anchors.centerIn: parent
			}
		}
	}
	
	// ================= DIALOGS =================
	Connections {
		target: btModel
		
		function onPairingRequired(address) {
			pairingDialog.targetAddress = address
			pairingDialog.open()
		}
		
		function onConnectionFailed(address) {
			connectionDialog.targetAddress = address
			connectionDialog.open()
		}
	}
	
	// Pairing dialog
	Dialog {
		id: pairingDialog
		modal: true
		focus: true
		width: 320
		height: 180
		anchors.centerIn: parent
		property string targetAddress: ""
		
		background: Rectangle {
			color: "#111111"
			radius: 10
			border.color: "#333333"
		}
		
		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 16
			spacing: 14
			
			Label {
				text: "Pair with device?"
				color: "white"
				font.pixelSize: 18
				Layout.alignment: Qt.AlignHCenter
			}
			
			Label {
				text: pairingDialog.targetAddress
				color: "#aaaaaa"
				font.pixelSize: 13
				Layout.alignment: Qt.AlignHCenter
			}
			
			RowLayout {
				Layout.fillWidth: true
				spacing: 10
				
				Button {
					text: "Cancel"
					Layout.fillWidth: true
					background: Rectangle { color: "#2b2b2b"; radius: 6 }
					onClicked: pairingDialog.close()
				}
				
				Button {
					text: "Pair"
					Layout.fillWidth: true
					background: Rectangle { color: "#0078d7"; radius: 6 }
					
					onClicked: {
						btModel.toggleConnection(pairingDialog.targetAddress, false)
						pairingDialog.close()
					}
				}
			}
		}
	}
	
	// Connection failed dialog
	Dialog {
		id: connectionDialog
		modal: true
		focus: true
		width: 320
		height: 150
		anchors.centerIn: parent
		property string targetAddress: ""
		
		background: Rectangle {
			color: "#111111"
			radius: 10
			border.color: "#333333"
		}
		
		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 16
			spacing: 14
			
			Label {
				text: "Connection failed"
				color: "white"
				font.pixelSize: 18
				Layout.alignment: Qt.AlignHCenter
			}
			
			Label {
				text: connectionDialog.targetAddress
				color: "#aaaaaa"
				font.pixelSize: 13
				Layout.alignment: Qt.AlignHCenter
			}
			
			Button {
				text: "OK"
				Layout.fillWidth: true
				background: Rectangle { color: "#0078d7"; radius: 6 }
				onClicked: connectionDialog.close()
			}
		}
	}
}
