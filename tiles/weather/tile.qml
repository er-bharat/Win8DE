import QtQuick 2.15
// import QtQuick.Controls 2.15

Item {
	id: liveWeatherTile
	anchors.fill: parent
	
	property string weatherApiKey: "your openweathermap API key"
	
	property var cities: [
		{ name: "Madhubani" },
		{ name: "Delhi" },
		{ name: "London" },
		{ name: "Tokyo" }
	]
	
	
	property int currentIndex: 0
	property var currentCity: ({
		name: "",
		temperature: 0,
		weather: "",
		iconUrl: "",
		tempHigh: 0,
		tempLow: 0,
		weatherDesc: ""
	})
	
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: nextCity()
	}
	
	function getWeatherColor(w) {
		if (!w) return "transparent"
			switch (w.toLowerCase()) {
				case "clear": return "#4A90E2"
				case "clouds": return "#90A4AE"
				case "rain": return "#3F51B5"
				case "drizzle": return "#5C6BC0"
				case "thunderstorm": return "#9C27B0"
				case "snow": return "#7dfc57"
				case "mist": return "#B0BEC5"
				case "smoke": return "#757575"
				case "haze": return "#CFD8DC"
				case "dust": return "#D7CCC8"
				case "fog": return "#90A4AE"
				case "sand": return "#F4E1C1"
				case "ash": return "#B0AFAF"
				case "squall": return "#607D8B"
				case "tornado": return "#FF5722"
				default: return "transparent"
			}
	}
	
	function nextCity() {
		var nextIndex = (currentIndex + 1) % cities.length
		var next = cities[nextIndex]
		
		nextTile.y = liveWeatherTile.height
		nextTile.cityName = next.name
		nextTile.temperature = next.temperature || 0
		nextTile.tempHigh = next.tempHigh || 0
		nextTile.tempLow = next.tempLow || 0
		nextTile.weather = next.weather || ""
		nextTile.weatherDesc = next.weatherDesc || ""
		nextTile.iconUrl = next.iconUrl || ""
		nextTile.bgColor = getWeatherColor(next.weather)
		
		slideAnim.start()
		currentIndex = nextIndex
	}
	
	// ===== Tiles stacked =====
	Item {
		id: tileStack
		anchors.fill: parent
		
		Rectangle {
			id: currentTile
			width: parent.width
			height: parent.height
			x: 0
			y: 0
			visible: currentCity.weather !== ""
			
			property string cityName: currentCity.name
			property real temperature: currentCity.temperature
			property real tempHigh: currentCity.tempHigh
			property real tempLow: currentCity.tempLow
			property string weather: currentCity.weather
			property string weatherDesc: currentCity.weatherDesc
			property string iconUrl: currentCity.iconUrl
			property color bgColor: currentCity.weather ? getWeatherColor(currentCity.weather) : "transparent"
			
			// Gradient background
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: Qt.darker(currentTile.bgColor, 1.2) } // left slightly darker
				GradientStop { position: 1.0; color: Qt.lighter(currentTile.bgColor, 1.2) } // right slightly lighter
			}
			
			// Icon – top right
			Image {
				source: currentTile.iconUrl
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: parent.width * 0.06
				width: parent.width * 0.28
				height: width
				fillMode: Image.PreserveAspectFit
				visible: currentTile.iconUrl !== ""
				opacity: 0.9
			}
			
			Column {
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.margins: parent.width * 0.08
				width: parent.width * 0.7
				spacing: parent.height * 0.015
				
				// Current temperature (hero)
				Text {
					text: Math.round(currentTile.temperature) + "°"
					color: "white"
					font.pixelSize: parent.width * 0.30
					font.weight: Font.Thin
					lineHeight: 0.9
				}
				
				// City name
				Text {
					text: currentTile.cityName
					color: "#E6FFFFFF"
					font.pixelSize: parent.width * 0.10
					font.weight: Font.Light
				}
				
				// Weather main
				Text {
					text: currentTile.weather
					color: "#CCFFFFFF"
					font.pixelSize: parent.width * 0.085
					font.weight: Font.Light
				}
				
				// Small spacer
				Item { height: parent.height * 0.02 }
				
				// TODAY label
				Text {
					text: "Today"
					color: "#99FFFFFF"
					font.pixelSize: parent.width * 0.075
					font.weight: Font.Light
				}
				
				// H/L + description on one line
				Text {
					text: Math.round(currentTile.tempHigh) + "°/" + Math.round(currentTile.tempLow) + "°  " +
					(currentTile.weatherDesc || currentTile.weather)
					color: "#E6FFFFFF"
					font.pixelSize: parent.width * 0.085
					font.weight: Font.Light
					wrapMode: Text.Wrap
				}
			}
		}
		
		
		
		Rectangle {
			id: nextTile
			width: parent.width
			height: parent.height
			x: 0
			y: parent.height
			visible: nextTile.weather !== ""
			
			property string cityName: ""
			property real temperature: 0
			property real tempHigh: 0
			property real tempLow: 0
			property string weather: ""
			property string weatherDesc: ""
			property string iconUrl: ""
			property color bgColor: "transparent"
			
			// Gradient background
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: Qt.darker(nextTile.bgColor, 1.2) } // left slightly darker
				GradientStop { position: 1.0; color: Qt.lighter(nextTile.bgColor, 1.2) } // right slightly lighter
			}
			
			// Icon – top right
			Image {
				source: nextTile.iconUrl
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: parent.width * 0.06
				width: parent.width * 0.28
				height: width
				fillMode: Image.PreserveAspectFit
				visible: nextTile.iconUrl !== ""
				opacity: 0.9
			}
			
			Column {
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.margins: parent.width * 0.08
				width: parent.width * 0.7
				spacing: parent.height * 0.015
				
				Text {
					text: Math.round(nextTile.temperature) + "°"
					color: "white"
					font.pixelSize: parent.width * 0.30
					font.weight: Font.Thin
					lineHeight: 0.9
				}
				
				Text {
					text: nextTile.cityName
					color: "#E6FFFFFF"
					font.pixelSize: parent.width * 0.10
					font.weight: Font.Light
				}
				
				Text {
					text: nextTile.weather
					color: "#CCFFFFFF"
					font.pixelSize: parent.width * 0.085
					font.weight: Font.Light
				}
				
				Item { height: parent.height * 0.02 }
				
				Text {
					text: "Today"
					color: "#99FFFFFF"
					font.pixelSize: parent.width * 0.075
					font.weight: Font.Light
				}
				
				Text {
					text: Math.round(nextTile.tempHigh) + "°/" + Math.round(nextTile.tempLow) + "°  " +
					(nextTile.weatherDesc || nextTile.weather)
					color: "#E6FFFFFF"
					font.pixelSize: parent.width * 0.085
					font.weight: Font.Light
					wrapMode: Text.Wrap
				}
			}
		}
		
		
		
	}
	
	NumberAnimation {
		id: slideAnim
		target: nextTile
		property: "y"
		from: liveWeatherTile.height
		to: 0
		duration: 600
		easing.type: Easing.InOutQuad
		onStarted: currentTileAnim.start()
		onStopped: {
			currentCity = {
				name: nextTile.cityName,
				temperature: nextTile.temperature,
				tempHigh: nextTile.tempHigh,
				tempLow: nextTile.tempLow,
				weather: nextTile.weather,
				weatherDesc: nextTile.weatherDesc,
				iconUrl: nextTile.iconUrl,
			}
			nextTile.y = liveWeatherTile.height
			currentTile.y = 0
		}
	}
	
	NumberAnimation {
		id: currentTileAnim
		target: currentTile
		property: "y"
		from: 0
		to: -liveWeatherTile.height
		duration: 600
		easing.type: Easing.InOutQuad
	}
	
	Component.onCompleted: {
		var c = cities[0]
		currentCity = { name: c.name, temperature: 0, weather: "", iconUrl: "", tempHigh: 0, tempLow: 0, weatherDesc: "", apiKey: c.apiKey }
		loadAllCities()
	}
	
	function loadAllCities() {
		for (var i = 0; i < cities.length; ++i) fetchWeather(i)
	}
	
	function fetchWeather(index) {
		var city = cities[index]
		if (!weatherApiKey) return
			
			// 3-hourly forecast endpoint
			var xhr = new XMLHttpRequest()
			var url = "https://api.openweathermap.org/data/2.5/forecast?q="
			+ city.name
			+ "&units=metric&cnt=8&appid="
			+ weatherApiKey
			
			xhr.open("GET", url)
			xhr.onreadystatechange = function () {
				if (xhr.readyState === XMLHttpRequest.DONE) {
					if (xhr.status === 200) {
						var resp = JSON.parse(xhr.responseText)
						
						if (!resp.list || resp.list.length === 0) {
							return
						}
						
						// Current temp = first 3-hour entry
						city.temperature = resp.list[0].main.temp
						city.weather = resp.list[0].weather[0].main
						city.weatherDesc = resp.list[0].weather[0].description
						city.iconUrl =
						"https://openweathermap.org/img/wn/"
						+ resp.list[0].weather[0].icon
						+ "@2x.png"
						
						// Compute today's high and low from all 8 entries (~24 hours)
						var temps = resp.list.map(entry => entry.main.temp)
						city.tempHigh = Math.max.apply(null, temps)
						city.tempLow = Math.min.apply(null, temps)
						
						// Update currentCity if first index
						if (index === 0) {
							currentCity.temperature = city.temperature
							currentCity.tempHigh = city.tempHigh
							currentCity.tempLow = city.tempLow
							currentCity.weather = city.weather
							currentCity.weatherDesc = city.weatherDesc
							currentCity.iconUrl = city.iconUrl
						}
					}
				}
			}
			xhr.send()
	}
	
	
	
	Timer {
		interval: 60000
		repeat: true
		running: true
		onTriggered: loadAllCities()
	}
}
