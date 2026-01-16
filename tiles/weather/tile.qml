import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
	id: liveWeatherTile
	anchors.fill: parent
	
	property var cities: [
		{ name: "London", apiKey: "fe3e3304d71137b54df68ac1b0713b2c" },
		{ name: "Delhi", apiKey: "fe3e3304d71137b54df68ac1b0713b2c" },
		{ name: "Tokyo", apiKey: "fe3e3304d71137b54df68ac1b0713b2c" },
		{ name: "Madhubani", apiKey: "fe3e3304d71137b54df68ac1b0713b2c" }
	]
	
	property int currentIndex: 0
	property var currentCity: ({ name: "", temperature: 0, weather: "", iconUrl: "", apiKey: "" })
	
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: nextCity()
	}
	
	function getWeatherColor(w) {
		if (!w) return "transparent"
			
			switch (w.toLowerCase()) {
				case "clear": return "#4A90E2"            // sunny sky blue
				case "clouds": return "#90A4AE"           // grayish clouds
				case "rain": return "#3F51B5"             // deep blue rain
				case "drizzle": return "#5C6BC0"          // lighter blue drizzle
				case "thunderstorm": return "#9C27B0"     // purple storm
				case "snow": return "#7dfc57"             // light greenish-white snow
				case "mist": return "#B0BEC5"             // soft mist gray
				case "smoke": return "#757575"            // smoky gray
				case "haze": return "#CFD8DC"             // hazy light gray
				case "dust": return "#D7CCC8"             // dusty brownish
				case "fog": return "#90A4AE"              // fog gray
				case "sand": return "#F4E1C1"             // sandy beige
				case "ash": return "#B0AFAF"              // volcanic ash gray
				case "squall": return "#607D8B"           // stormy gray
				case "tornado": return "#FF5722"          // intense orange-red
				default: return "transparent"                     // fallback dark gray
			}
	}
	
	
	function nextCity() {
		var nextIndex = (currentIndex + 1) % cities.length
		var next = cities[nextIndex]
		
		nextTile.y = liveWeatherTile.height
		nextTile.cityName = next.name
		nextTile.temperature = next.temperature || 0
		nextTile.weather = next.weather || ""
		nextTile.iconUrl = next.iconUrl || ""
		nextTile.bgColor = getWeatherColor(next.weather)
		
		slideAnim.start()
		currentIndex = nextIndex
	}
	
	// ===== Tiles stacked =====
	Item {
		id: tileStack
		anchors.fill: parent
		
		// inside your currentTile Rectangle
		Rectangle {
			id: currentTile
			width: parent.width
			height: parent.height
			x: 0
			y: 0
			color: currentCity.weather ? getWeatherColor(currentCity.weather) : "transparent"
			visible: currentCity.weather !== "" // only show if weather is available
			
			property string cityName: currentCity.name
			property real temperature: currentCity.temperature
			property string weather: currentCity.weather
			property string iconUrl: currentCity.iconUrl
			property color bgColor: color
			
			Column {
				anchors.centerIn: parent
				spacing: 8
				width: parent.width * 0.9
				
				Text { text: currentTile.cityName; color: "white"; font.pixelSize: parent.width * 0.12; horizontalAlignment: Text.AlignHCenter }
				Image { source: currentTile.iconUrl; width: parent.width * 0.4; height: width; fillMode: Image.PreserveAspectFit; visible: currentTile.iconUrl !== "" }
				Text { text: currentTile.temperature.toFixed(1) + "°C"; color: "white"; font.bold: true; font.pixelSize: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter }
				Text { text: currentTile.weather; color: "white"; font.pixelSize: parent.width * 0.1; horizontalAlignment: Text.AlignHCenter }
			}
		}
		
		
		Rectangle {
			id: nextTile
			width: parent.width
			height: parent.height
			x: 0
			y: parent.height
			color: nextTile.bgColor
			visible: nextTile.weather !== "" // only show if weather is available
			
			property string cityName: ""
			property real temperature: 0
			property string weather: ""
			property string iconUrl: ""
			property color bgColor: "transparent"
			
			Column {
				anchors.centerIn: parent
				spacing: 8
				width: parent.width * 0.9
				
				Text { text: nextTile.cityName; color: "white"; font.pixelSize: parent.width * 0.12; horizontalAlignment: Text.AlignHCenter }
				Image { source: nextTile.iconUrl; width: parent.width * 0.4; height: width; fillMode: Image.PreserveAspectFit; visible: nextTile.iconUrl !== "" }
				Text { text: nextTile.temperature.toFixed(1) + "°C"; color: "white"; font.bold: true; font.pixelSize: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter }
				Text { text: nextTile.weather; color: "white"; font.pixelSize: parent.width * 0.1; horizontalAlignment: Text.AlignHCenter }
			}
		}
		
		
	}
	
	NumberAnimation {
		id: slideAnim
		target: nextTile
		property: "y"
		from: liveWeatherTile.height  // start below
		to: 0                        // slide into view
		duration: 600
		easing.type: Easing.InOutQuad
		onStarted: {
			// Animate the current tile up at the same time
			currentTileAnim.start()
		}
		onStopped: {
			currentCity = {
				name: nextTile.cityName,
				temperature: nextTile.temperature,
				weather: nextTile.weather,
				iconUrl: nextTile.iconUrl,
				apiKey: cities[currentIndex].apiKey
			}
			nextTile.y = liveWeatherTile.height // reset for next cycle
			currentTile.y = 0                    // reset current tile
		}
	}
	
	// Animate current tile moving up and out
	NumberAnimation {
		id: currentTileAnim
		target: currentTile
		property: "y"
		from: 0
		to: -liveWeatherTile.height  // move out above
		duration: 600
		easing.type: Easing.InOutQuad
	}
	
	
	Component.onCompleted: {
		var c = cities[0]
		currentCity = { name: c.name, temperature: 0, weather: "", iconUrl: "", apiKey: c.apiKey }
		loadAllCities()
	}
	
	function loadAllCities() {
		for (var i = 0; i < cities.length; ++i) fetchWeather(i)
	}
	
	function fetchWeather(index) {
		var city = cities[index]
		if (!city.apiKey) return
			
			var xhr = new XMLHttpRequest()
			var url = "https://api.openweathermap.org/data/2.5/weather?q=" + city.name + "&units=metric&appid=" + city.apiKey
			xhr.open("GET", url)
			xhr.onreadystatechange = function() {
				if (xhr.readyState === XMLHttpRequest.DONE) {
					if (xhr.status === 200) {
						var resp = JSON.parse(xhr.responseText)
						city.temperature = resp.main.temp
						city.weather = resp.weather[0].main
						city.iconUrl = "https://openweathermap.org/img/wn/" + resp.weather[0].icon + "@2x.png"
						
						if (index === 0) {
							currentCity.temperature = city.temperature
							currentCity.weather = city.weather
							currentCity.iconUrl = city.iconUrl
						}
					} else {
						console.warn("Weather API error:", xhr.status, xhr.responseText)
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
