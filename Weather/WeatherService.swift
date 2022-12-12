//
//  WeatherService.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation
import AppKit

struct Weather: Codable {
    let name: String
    let temp: Double
    let icon: String
    let description: String
    var temperature: String {
        guard temp > -999 else {
            return "Unknown information"
        }
        let units: String = Preferences[.units]
        switch units {
        case "fahrenheit":
            let converted = (temp * (9/5) + 32)
            return "\(Int(converted))°"
        default:
            return "\(Int(temp))°"
        }
    }
}

struct OMWeather: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
}

struct WeatherData: Codable {
    struct Metadata: Codable {
        let error: String?
        let code: Int
    }
    let metadata: Metadata
    let weather: Weather
    private enum CodingKeys: String, CodingKey {
        case weather = "data", metadata
    }
}

let descriptions = [
    0: "clear sky",
    1: "mainly clear",
    2: "partly cloudy",
    3: "overcast",
    45: "foggy",
    48: "foggy",
    51: "light drizzle",
    53: "drizzle",
    55: "heavy drizzle",
    56: "light freezing drizzle",
    57: "dense freezing drizzle",
    61: "light rain",
    63: "rain",
    65: "heavy rain",
    66: "light freezing rain",
    67: "heavy freezing rain",
    71: "light snow fall",
    73: "snow fall",
    75: "heavy snow fall",
    77: "snow grains",
    80: "light rain showers",
    81: "rain showers",
    82: "violent rain showers",
    85: "light snow showers",
    86: "heavy snow showers",
    95: "thunderstorm",
    96: "hail",
    99: "hail",
]

let wmoToOwmIcon = [
    0: "01",
    1: "01",
    2: "02",
    3: "03",
    45: "50",
    48: "50",
    51: "10",
    53: "10",
    55: "10",
    56: "13",
    57: "13",
    61: "10",
    63: "10",
    65: "10",
    66: "13",
    67: "13",
    71: "13",
    73: "13",
    75: "13",
    77: "13",
    80: "10",
    82: "10",
    85: "13",
    86: "13",
    95: "11",
    96: "11",
    99: "11",
]

internal class WeatherService {
    
    // https://weather.navalia.app/weather?lat=52.37&lon=4.88&units=celsius
    // https://weather.navalia.app/condition?lat=52.37&lon=4.88&units=celsius&name=Dam
    
    func currentConditions(for coordinate: CLLocationCoordinate2D, cityName: String, result: @escaping (WeatherData?) -> Void) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&current_weather=true"
        guard let escaped = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: escaped) else {
            print("[WeatherService]: Invalid URL: \(urlString)")
            result(nil)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = URLSession.shared.dataTask(with: request) { [result] data, response, error in
            print("[WeatherService]: \((response as? HTTPURLResponse)?.statusCode ?? -999)")
            let name: String = Preferences[.city_name]
            guard error == nil, let data = data else {
                let data = WeatherData(
                    metadata: .init(error: nil, code: -999),
                    weather: Weather(
                        name: name,
                        temp: -999,
                        icon: NSImage.touchBarSearchTemplateName,
                        description: "Unknown information"
                    )
                )
                result(data)
                return
            }
            do {
                let weather = try JSONDecoder().decode(OMWeather.self, from: data)
                let date = Date()
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: date)
                
                result(WeatherData(
                        metadata: .init(error: nil, code: 200),
                        weather: Weather(
                                name: name,
                                temp: weather.current_weather.temperature,
                                icon: "\(wmoToOwmIcon[weather.current_weather.weathercode] ?? "")\((hour > 18 || hour < 6) ? "n" : "d")",
                                description: descriptions[weather.current_weather.weathercode] ?? "Unknown"
                        )
                ))
            } catch {
                let data = WeatherData(
                    metadata: .init(error: nil, code: -999),
                    weather: Weather(
                        name: name,
                        temp: -999,
                        icon: NSImage.touchBarSearchTemplateName,
                        description: "Unknown information"
                    )
                )
                result(data)
            }
        }
        session.resume()
    }
    
}
