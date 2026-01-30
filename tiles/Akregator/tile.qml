import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
	id: rssTile
	anchors.fill: parent
	clip: true
	
	property string rssUrl: "http://feeds.bbci.co.uk/news/world/rss.xml"
	property int maxItems: 10
	property string placeholderImage: "https://via.placeholder.com/800x400?text=News"
	
	property var rssItems: []
	property int currentIndex: 0
	property var currentItem: ({ title: "", image: "", link: "" })
	
	/* ================= FETCH RSS ================= */
	
	function fetchRSS() {
		var xhr = new XMLHttpRequest()
		xhr.open("GET", rssUrl)
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
				rssItems = []
				var xml = xhr.responseText
				var blocks = xml.match(/<item[\s\S]*?<\/item>/gi)
				
				for (var i = 0; i < Math.min(blocks.length, maxItems); i++) {
					var block = blocks[i]
					
					var titleMatch = block.match(/<title><!\[CDATA\[([\s\S]*?)\]\]><\/title>/i)
					var linkMatch = block.match(/<link>([\s\S]*?)<\/link>/i)
					var imgMatch =
					block.match(/<media:[^>]+url=["']([^"']+)["']/i) ||
					block.match(/<enclosure[^>]+type=["']image\/[^"']+["'][^>]+url=["']([^"']+)["']/i)
					
					rssItems.push({
						title: titleMatch ? titleMatch[1] : "No title",
						link: linkMatch ? linkMatch[1] : "",
						image: imgMatch ? imgMatch[1] : placeholderImage
					})
				}
				
				if (rssItems.length > 0) {
					currentIndex = 0
					currentItem = rssItems[0]
					currentImage.source = currentItem.image
					rotateTimer.start()
				}
			}
		}
		xhr.send()
	}
	
	Component.onCompleted: fetchRSS()
	
	/* ================= TILES ================= */
	
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
			y: parent.height
		}
		
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: parent.height / 2
			gradient: Gradient {
				GradientStop { position: 0.0; color: "transparent" }
				GradientStop { position: 1.0; color: "#CC000000" }
			}
		}
		
		Text {
			text: currentItem.title
			color: "white"
			font.pixelSize: parent.width * 0.055
			font.bold: true
			wrapMode: Text.WordWrap
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.margins: 12
		}
	}
	
	Rectangle {
		id: nextTile
		width: parent.width
		height: parent.height
		y: parent.height
		color: "transparent"
		clip: true
		
		property string title: ""
		property string image: ""
		property string link: ""
		
		Image {
			id: nextImage
			width: parent.width
			height: parent.height * 2
			fillMode: Image.PreserveAspectCrop
			y: 0
		}
		
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: parent.height / 2
			gradient: Gradient {
				GradientStop { position: 0.0; color: "transparent" }
				GradientStop { position: 1.0; color: "#CC000000" }
			}
		}
		
		Text {
			text: nextTile.title
			color: "white"
			font.pixelSize: parent.width * 0.055
			font.bold: true
			wrapMode: Text.WordWrap
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.margins: 12
		}
	}
	
	/* ================= SLIDE ANIMATION ================= */
	
	ParallelAnimation {
		id: slideAnim
		
		NumberAnimation {
			target: nextTile
			property: "y"
			from: height
			to: 0
			duration: 600
			easing.type: Easing.InExpo
		}
		
		NumberAnimation {
			target: currentTile
			property: "y"
			from: 0
			to: -height
			duration: 600
			easing.type: Easing.InExpo
		}
		
		onStopped: {
			currentItem = {
				title: nextTile.title,
				image: nextTile.image,
				link: nextTile.link
			}
			
			currentImage.source = nextImage.source
			currentTile.y = 0
			nextTile.y = height
			currentImage.y = height
			nextImage.y = 0
		}
	}
	
	/* ================= PARALLAX IMAGE MOTION ================= */
	
	ParallelAnimation {
		id: imageSlide
		
		SequentialAnimation {
			NumberAnimation {
				target: nextImage
				property: "y"
				from: 0
				to: -height / 2
				duration: 4200
				easing.type: Easing.Linear
			}
			NumberAnimation {
				target: nextImage
				property: "y"
				from: -height / 2
				to: 0
				duration: 4200
				easing.type: Easing.Linear
			}
		}
		
		SequentialAnimation {
			NumberAnimation {
				target: currentImage
				property: "y"
				from: 0
				to: -height / 2
				duration: 4200
				easing.type: Easing.Linear
			}
			NumberAnimation {
				target: currentImage
				property: "y"
				from: -height / 2
				to: 0
				duration: 4200
				easing.type: Easing.Linear
			}
		}
	}
	
	/* ================= ROTATION TIMER ================= */
	
	Timer {
		id: rotateTimer
		interval: 9000
		repeat: true
		running: rssItems.length > 1
		
		onTriggered: {
			var next = (currentIndex + 1) % rssItems.length
			var item = rssItems[next]
			
			nextTile.title = item.title
			nextTile.image = item.image
			nextTile.link = item.link
			nextImage.source = item.image
			
			slideAnim.start()
			imageSlide.start()
			
			currentIndex = next
		}
	}
	Timer {
		id: rotateTimer2
		interval: 900
		repeat: false
		running: rssItems.length > 1
		
		onTriggered: {
			var next = (currentIndex + 1) % rssItems.length
			var item = rssItems[next]
			
			nextTile.title = item.title
			nextTile.image = item.image
			nextTile.link = item.link
			nextImage.source = item.image
			
			slideAnim.start()
			imageSlide.start()
			
			currentIndex = next
		}
	}
}
