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
					id: wifiswitch
					checked: wifiModel.wifiEnabled
					onToggled: {
						wifiModel.wifiEnabled = checked
						wifiModel.refreshWifi()
					}
					
					
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
			
			Layout.fillWidth: true
			onClicked: wifiModel.refreshWifi()
			background: Rectangle {
				color: "#55557c"
				radius: 0
			}
			contentItem: Text {
				text: "scan"
				color: "#ffffff"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				anchors.centerIn: parent
			}
		}
		Timer {
			id: autoScanTimer
			interval: 1000   // 5 seconds
			running: wifiswitch.checked
			repeat: true
			triggeredOnStart: true
			onTriggered: wifiModel.refreshWifi()
		}
	}
	Connections {
		target: wifiModel
		
		function onPasswordRequired(ssid) {
			passwordDialog.targetSSID = ssid
			passwordField.text = ""
			passwordDialog.open()
		}
	}
	Dialog {
		id: passwordDialog
		
		modal: true
		focus: true
		
		width: 320
		height: 190
		
		anchors.centerIn: parent
		
		property string targetSSID: ""
		
		background: Rectangle {
			color: "#111111"
			radius: 0
			border.color: "#969696"
		}
		
		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 16
			spacing: 14
			
			Label {
				text: "Enter password"
				color: "white"
				font.pixelSize: 18
				Layout.alignment: Qt.AlignHCenter
			}
			
			Label {
				text: passwordDialog.targetSSID
				color: "#aaaaaa"
				font.pixelSize: 13
				Layout.alignment: Qt.AlignHCenter
			}
			
			TextField {
				id: passwordField
				Layout.fillWidth: true
				
				echoMode: TextInput.Password
				placeholderText: "Wi-Fi password"
				
				color: "white"
				placeholderTextColor: "#777"
				
				background: Rectangle {
					color: "#1b1b1b"
					radius: 0
					border.color: "#444"
				}
			}
			
			RowLayout {
				Layout.fillWidth: true
				spacing: 10
				
				Button {
					text: "Cancel"
					Layout.fillWidth: true
					
					background: Rectangle {
						color: "#2b2b2b"
						radius: 6
					}
					
					onClicked: passwordDialog.close()
				}
				
				Button {
					text: "Connect"
					Layout.fillWidth: true
					
					background: Rectangle {
						color: "#0078d7"
						radius: 6
					}
					
					onClicked: {
						wifiModel.toggleConnection(
							passwordDialog.targetSSID,
							false,
							passwordField.text
						)
						
						passwordDialog.close()
					}
				}
			}
		}
	}
	
	
}
