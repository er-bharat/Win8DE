import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.folderlistmodel 2.15

Item {
	id: liveGalleryTile
	anchors.fill: parent
	clip: true
	
	property url imageFolder: "file:///home/bharat/Pictures/india gate/edited"
	property int currentIndex: 0
	
	FolderListModel {
		id: imageModel
		folder: imageFolder
		nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.bmp", "*.webp"]
		showDirs: false
		sortField: FolderListModel.Time
		sortReversed: true
		
		onCountChanged: {
			if (count > 0 && currentImage.source === "") {
				currentIndex = 0
				currentImage.source = get(0, "fileUrl")   // ✅ correct role
			}
		}
	}
	
	Rectangle {
		id: currentTile
		width: parent.width
		height: parent.height
		color: "transparent"
		clip: true
		
		Image {
			id: currentImage
			width: parent.width
			height: parent.height * 2
			fillMode: Image.PreserveAspectCrop
		}
	}
	
	Rectangle {
		id: nextTile
		width: parent.width
		height: parent.height
		y: parent.height
		color: "transparent"
		clip: true
		
		Image {
			id: nextImage
			width: parent.width
			height: parent.height * 2
			fillMode: Image.PreserveAspectCrop
		}
	}
	
	ParallelAnimation {
		id: slideAnim
		
		NumberAnimation {
			target: nextTile
			property: "y"
			from: height
			to: 0
			duration: 600
			easing.type: Easing.InOutQuad
		}
		
		NumberAnimation {
			target: currentTile
			property: "y"
			from: 0
			to: -height
			duration: 600
			easing.type: Easing.InOutQuad
		}
		
		onStopped: {
			currentImage.source = nextImage.source
			currentTile.y = 0
			nextTile.y = height
			currentIndex = (currentIndex + 1) % imageModel.count
		}
	}
	
	ParallelAnimation {
		id: imageslide
		
		NumberAnimation {
			target: nextImage
			property: "y"
			from: 0
			to: -height/2
			duration: 1700
			easing.type: Easing.InOutQuad
		}
		
		NumberAnimation {
			target: nextImage
			property: "y"
			from: -height/2
			to: 0
			duration: 1700
			easing.type: Easing.InOutQuad
		}
		
		NumberAnimation {
			target: currentImage
			property: "y"
			from: 0
			to: -height/2
			duration: 1700
			easing.type: Easing.InOutQuad
		}
		NumberAnimation {
			target: currentImage
			property: "y"
			from: -height/2
			to: 0
			duration: 1700
			easing.type: Easing.InOutQuad
		}
	}
	
	Timer {
		interval: 4000
		repeat: true
		running: imageModel.count > 1
		
		onTriggered: {
			if (imageModel.count < 2)
				return
				
				var nextIndex = (currentIndex + 1) % imageModel.count
				var url = imageModel.get(nextIndex, "fileUrl")   // ✅ correct role
				
				if (url !== undefined && url !== "") {
					nextImage.source = url
					slideAnim.start()
					imageslide.start()
				}
		}
	}
	
	Text {
		anchors.centerIn: parent
		visible: imageModel.count === 0
		text: "No Photos"
		color: "white"
		font.pixelSize: parent.width * 0.1
	}
}
