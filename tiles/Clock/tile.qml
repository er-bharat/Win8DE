import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
	id: worldClockTile
	width: parent ? parent.width : 400
	height: parent ? parent.height : 300
	
	/* ===== Cities ===== */
	property var cities: [
		{ name: "Delhi", offset: 5.5 },
		{ name: "London", offset: 0 },
		{ name: "Tokyo", offset: 9 },
		{ name: "New York", offset: -5 }
	]
	
	property int currentIndex: 0
	property var currentCity: ({ name: "", time: "", date: "", bgColor: "transparent" })
	
	/* ===== Timers ===== */
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: nextCity()
	}
	
	Timer {
		interval: 60000
		running: true
		repeat: true
		onTriggered: updateCurrentTime()
	}
	
	function cityDateTime(offset) {
		var now = new Date()
		var utc = now.getTime() + now.getTimezoneOffset() * 60000
		return new Date(utc + offset * 3600000)
	}
	
	function getBackgroundColor(dt) {
		var hour = dt.getHours()
		
		if (hour >= 5 && hour < 7)
			return "#FFB74D"      // Sunrise
			else if (hour >= 7 && hour < 17)
				return "#4A90E2"      // Day
				else if (hour >= 17 && hour < 19)
					return "#BA68C8"      // Sunset
					else
						return "#0D1B2A"      // Night
	}
	
	function updateCurrentTime() {
		var c = cities[currentIndex]
		var dt = cityDateTime(c.offset)
		
		currentCity.time = Qt.formatDateTime(dt, "HH:mm")
		currentCity.date = Qt.formatDateTime(dt, "dddd, dd, MMM")
		currentCity.bgColor = getBackgroundColor(dt)
	}
	
	function nextCity() {
		var nextIndex = (currentIndex + 1) % cities.length
		var next = cities[nextIndex]
		
		var dt = cityDateTime(next.offset)
		
		nextTile.y = height
		nextTile.cityName = next.name
		nextTile.time = Qt.formatDateTime(dt, "HH:mm")
		nextTile.date = Qt.formatDateTime(dt, "dddd, dd, MMM")
		nextTile.bgColor = getBackgroundColor(dt)
		
		slideAnim.start()
		currentIndex = nextIndex
	}
	
	/* ===== Tile Stack ===== */
	Item {
		width: parent.width
		height: parent.height
		
		Rectangle {
			id: currentTile
			width: parent.width
			height: parent.height
			y: 0
			color: currentCity.bgColor
			
			property string cityName: currentCity.name
			property string time: currentCity.time
			property string date: currentCity.date
			property color bgColor: "transparent"
			
			Row {
				width: parent.width
				height: parent.height
			
				Rectangle {
					id: vertrect
					width: parent.width/5
					height: parent.height
					color: "#46495e"
					
					Text {
						anchors.centerIn: parent
						id: verticalCity
						text: currentTile.cityName
						font.pixelSize: worldClockTile.width * 0.2
						font.weight: Font.Black
						color: currentTile.color
						rotation: 270
					}
				}
			
				Item {
					width: (parent.width/5)*4
					height: parent.height
					Column {
						anchors.centerIn: parent
						spacing: parent.height/ 20
						width: (parent.width - vertrect.width)*0.9
						
						Text {
							text: currentTile.time
							font.pixelSize: parent.width * 0.5
							font.weight: Font.Light
							color: "white"
							horizontalAlignment: Text.AlignHCenter
							width: parent.width
						}
						
						Text {
							text: currentTile.date
							font.pixelSize: parent.width * 0.3
							font.weight: Font.Thin
							color: "#E0E0E0"
							// horizontalAlignment: Text.AlignHCenter
							width: parent.width
							wrapMode: TextEdit.WordWrap
						}
					}
				}
			}
		}
		
		Rectangle {
			id: nextTile
			width: parent.width
			height: parent.height
			y: parent.height
			color: nextTile.bgColor
			
			property string cityName: ""
			property string time: ""
			property string date: ""
			property color bgColor: "transparent"
			
			Row {
				width: parent.width
				height: parent.height
				Rectangle {
					id: vertrectnext
					width: parent.width/5
					height: parent.height
					color: "#46495e"
					
					Text {
						anchors.centerIn: parent
						id: verticalCitynext
						text: nextTile.cityName
						font.pixelSize: worldClockTile.width * 0.2
						font.weight: Font.Black
						color: nextTile.color
						rotation: 270
					}
				}
				Item {
					width: (parent.width/5)*4
					height: parent.height
					
					Column {
						anchors.centerIn: parent
						spacing: 10
						width: (parent.width - vertrectnext.width)*0.9
						
						Text {
							text: nextTile.time
							font.pixelSize: parent.width * 0.5
							font.weight: Font.Light
							color: "white"
							horizontalAlignment: Text.AlignHCenter
							width: parent.width
						}
						
						Text {
							text: nextTile.date
							font.pixelSize: parent.width * 0.3
							font.weight: Font.Thin
							color: "#E0E0E0"
							// horizontalAlignment: Text.AlignHCenter
							width: parent.width
							wrapMode: TextEdit.WordWrap
							
						}
					}
				}
				
			}
			
			
		}
	}
	
	/* ===== Animations ===== */
	NumberAnimation {
		id: slideAnim
		target: nextTile
		property: "y"
		from: worldClockTile.height
		to: 0
		duration: 600
		easing.type: Easing.InOutQuad
		onStarted: currentTileAnim.start()
		onStopped: {
			currentCity = {
				name: nextTile.cityName,
				time: nextTile.time,
				date: nextTile.date,
				bgColor: nextTile.bgColor
			}
			nextTile.y = worldClockTile.height
			currentTile.y = 0
		}
	}
	
	NumberAnimation {
		id: currentTileAnim
		target: currentTile
		property: "y"
		from: 0
		to: -worldClockTile.height
		duration: 600
		easing.type: Easing.InOutQuad
	}
	
	Component.onCompleted: {
		var c = cities[0]
		var dt = cityDateTime(c.offset)
		currentCity = {
			name: c.name,
			time: Qt.formatDateTime(dt, "HH:mm"),
			date: Qt.formatDateTime(dt, "dddd, dd, MMM"),
			bgColor: getBackgroundColor(dt)
		}
	}
}
