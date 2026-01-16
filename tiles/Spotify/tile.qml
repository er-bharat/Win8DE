import QtQuick 2.15
import QtQuick.Window 2.15

Item {
	id: art
	anchors.fill: parent
	
	Rectangle {
		anchors.fill: parent
		color: "transparent"
		
		Image {
			id: animatedImage
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width
			height: parent.height * 1.5
			source: Qt.resolvedUrl("art.jpg")
			cache: false
			fillMode: Image.PreserveAspectCrop
			smooth: true
			y: -height * 0.25
			
			onStatusChanged: {
				if (status === Image.Error)
					console.log("Failed to load image:", source)
			}
			
			SequentialAnimation {
				id: moveAnim
				loops: Animation.Infinite
				running: true
				
				NumberAnimation {
					target: animatedImage
					property: "y"
					from: -animatedImage.height * 0.25
					to: 0
					duration: 10000
					easing.type: Easing.InOutQuad
				}
				
				NumberAnimation {
					target: animatedImage
					property: "y"
					from: 0
					to: -animatedImage.height * 0.25
					duration: 10000
					easing.type: Easing.InOutQuad
				}
			}
		}
	}
	
	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: {
			animatedImage.source = ""
			animatedImage.source = Qt.resolvedUrl("art.jpg")
		}
	}
}
