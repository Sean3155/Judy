import Foundation

struct WeatherAdviceEngine {
    
    static func generateAdvice(from weather: WeatherResponse) -> WeatherAdvice {
        let feelsLike = weather.main.feelsLike
        let humidity = weather.main.humidity
        let windSpeed = weather.wind.speed
        let windGust = weather.wind.gust
        let description = weather.weather.first?.description.lowercased() ?? ""
        
        let comfort = determineComfortLevel(
            feelsLike: feelsLike,
            humidity: humidity
        )
        let windImpact = determineWindImpact(windSpeed: windSpeed)
        let rainImpact = determineRainImpact(description: description)
        
        let clothing = generateClothingRecommendations(
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeed: windSpeed,
            rainImpact: rainImpact
        )
        
        let cautions = generateCautions(
            feelsLike: feelsLike,
            windImpact: windImpact,
            rainImpact: rainImpact,
            windGust: windGust,
            description: description
        )
        
        let summary = generateSummary(
            comfort: comfort,
            windImpact: windImpact,
            rainImpact: rainImpact
        )
        
        let comfortNote = generateComfortNote(
            feelsLike: feelsLike,
            humidity: humidity,
            windImpact: windImpact,
            rainImpact: rainImpact
        )
        
        let walkComfortScore = calculateWalkComfortScore(
            feelsLike: feelsLike,
            humidity: humidity,
            windImpact: windImpact,
            rainImpact: rainImpact,
            windGust: windGust
        )

        let shortWalkOkay = isGoodForShortWalk(
            feelsLike: feelsLike,
            rainImpact: rainImpact,
            walkComfortScore: walkComfortScore
        )
        
        let longWalkOkay = isGoodForLongWalk(
            feelsLike: feelsLike,
            windImpact: windImpact,
            rainImpact: rainImpact,
            walkComfortScore: walkComfortScore
        )

        let walkComfortScore = calculateWalkComfortScore(
            feelsLike: feelsLike,
            humidity: humidity,
            windImpact: windImpact,
            rainImpact: rainImpact,
            windGust: windGust
        )

        return WeatherAdvice(
            comfortLevel: comfort,
            windImpact: windImpact,
            rainImpact: rainImpact,
            clothingRecommendations: clothing,
            cautions: cautions,
            summary: summary,
            comfortNote: comfortNote,
            isGoodForShortWalk: shortWalkOkay,
            isGoodForLongWalk: longWalkOkay,
            walkComfortScore: walkComfortScore
        )
    }
}

// MARK: - Core Logic
private extension WeatherAdviceEngine {
    
    static func determineComfortLevel(
        feelsLike: Double,
        humidity: Int
    ) -> ComfortLevel {
        var adjustedFeelsLike = feelsLike

        if humidity >= 75 && feelsLike >= 22 {
            adjustedFeelsLike += 2
        }

        if humidity <= 30 && feelsLike <= 8 {
            adjustedFeelsLike -= 2
        }

        switch adjustedFeelsLike {
        case ..<0:
            return .freezing
        case 0..<8:
            return .cold
        case 8..<15:
            return .cool
        case 15..<22:
            return .mild
        case 22..<28:
            return .warm
        default:
            return .hot
        }
    }

    static func determineWindImpact(windSpeed: Double) -> WindImpactLevel {
        switch windSpeed {
        case ..<3:
            return .low
        case 3..<8:
            return .moderate
        default:
            return .high
        }
    }
    
    static func determineRainImpact(description: String) -> RainImpactLevel {
        if description.contains("thunderstorm")
            || description.contains("very heavy rain")
            || description.contains("extreme rain")
            || description.contains("heavy intensity rain") {
            return .heavy
        } else if description.contains("light rain") || description.contains("drizzle") {
            return .light
        } else if description.contains("rain") || description.contains("snow") {
            return .moderate
        } else {
            return .none
        }
    }
    
    static func generateClothingRecommendations(
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        rainImpact: RainImpactLevel
    ) -> [String] {
        var items: [String] = []
        
        switch feelsLike {
        case ..<0:
            items.append("heavy coat")
            items.append("gloves")
            items.append("warm layers")
        case 0..<8:
            items.append("coat or insulated jacket")
            items.append("long pants")
        case 8..<15:
            items.append("light jacket or hoodie")
            items.append("long pants")
        case 15..<22:
            items.append("light outer layer")
        case 22..<28:
            items.append("t-shirt or light clothing")
        default:
            items.append("very light clothing")
            items.append("stay hydrated")
        }
        
        if windSpeed >= 8 {
            items.append("avoid loose outfits if you care about fit")
        }
        
        if rainImpact == .heavy {
            items.append("waterproof outer layer")
            items.append("umbrella")
        } else if rainImpact == .moderate {
            items.append("water-resistant outer layer")
        } else if rainImpact == .light {
            items.append("consider a light umbrella")
        }

        if humidity >= 80 && feelsLike >= 22 {
            items.append("breathable clothing")
        }
        
        return items
    }
    
    static func generateCautions(
        feelsLike: Double,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel,
        windGust: Double?,
        description: String
    ) -> [String] {
        var cautions: [String] = []
        
        if windImpact == .high {
            cautions.append("strong wind may mess up hair and loose clothing")
            cautions.append("hats may be annoying to keep on")
        } else if windImpact == .moderate {
            cautions.append("breeze may make it feel cooler than expected")
        }

        if let windGust, windGust >= 12, windImpact != .high {
            cautions.append("occasional wind gusts may still disrupt loose clothing")
        }
        
        if rainImpact == .light {
            cautions.append("light rain may still be annoying without coverage")
        } else if rainImpact == .moderate {
            cautions.append("getting wet is likely if you stay outside")
        } else if rainImpact == .heavy {
            cautions.append("heavy rain can make outdoor activity uncomfortable")
        }
        
        if feelsLike < 5 {
            cautions.append("it may feel colder than the raw temperature suggests")
        }
        
        if description.contains("snow") {
            cautions.append("watch for slippery ground")
        }

        if rainImpact == .heavy && feelsLike <= 2 {
            cautions.append("cold and wet conditions can feel especially harsh")
        }
        
        return cautions
    }
    
    static func generateSummary(
        comfort: ComfortLevel,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel
    ) -> String {
        switch (comfort, windImpact, rainImpact) {
        case (.freezing, _, _):
            return "This is a genuinely cold day, so dress for warmth first."
        case (.cold, .high, .none), (.cool, .high, .none):
            return "Not brutally cold, but the wind can make it pretty uncomfortable."
        case (.mild, .low, .none), (.warm, .low, .none):
            return "Overall, this is fairly comfortable weather."
        case (_, _, .heavy):
            return "Heavy rain is the main issue today and will likely make outside plans uncomfortable."
        case (_, _, .moderate):
            return "Wet conditions are likely to be the main comfort issue today."
        case (_, _, .light):
            return "Light rain may be manageable, but coverage will still help."
        case (.freezing, _, _):
            return "This is a genuinely cold day, so dress for warmth first."
        default:
            return "Conditions are manageable, but small details may affect comfort."
        }
    }
    
    static func generateComfortNote(
        feelsLike: Double,
        humidity: Int,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel
    ) -> String {
        if rainImpact == .moderate || rainImpact == .heavy {
            return "A short trip may be fine, but staying outside for long could get uncomfortable fast."
        }

        if humidity >= 75 && feelsLike >= 22 {
            return "It may feel warmer and a bit sticky because humidity is high."
        }

        if humidity <= 30 && feelsLike <= 8 {
            return "Dry air can make this feel a little colder than expected."
        }
        
        if feelsLike < 8 && windImpact == .high {
            return "You might be okay for a quick walk, but longer outdoor time could feel rough."
        }
        
        if feelsLike >= 15 && windImpact == .low {
            return "For most people, this should feel pretty easy to deal with."
        }
        
        return "This should be okay in short bursts, depending on what you are wearing."
    }
    

    static func calculateWalkComfortScore(
        feelsLike: Double,
        humidity: Int,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel,
        windGust: Double?
    ) -> Int {
        var score = 100

        if feelsLike < -5 || feelsLike > 32 {
            score -= 35
        } else if feelsLike < 5 || feelsLike > 28 {
            score -= 20
        } else if feelsLike < 10 || feelsLike > 24 {
            score -= 10
        }

        switch windImpact {
        case .low:
            break
        case .moderate:
            score -= 10
        case .high:
            score -= 25
        }

        switch rainImpact {
        case .none:
            break
        case .light:
            score -= 10
        case .moderate:
            score -= 25
        case .heavy:
            score -= 40
        }

        if humidity >= 80 || humidity <= 25 {
            score -= 8
        }

        if let windGust, windGust >= 12 {
            score -= 8
        }

        return max(0, min(100, score))
    }

    static func isGoodForShortWalk(
        feelsLike: Double,
        rainImpact: RainImpactLevel,
        walkComfortScore: Int
    ) -> Bool {
        return feelsLike > -8 && rainImpact != .heavy && walkComfortScore >= 35
    }
    
    static func isGoodForLongWalk(
        feelsLike: Double,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel,
        walkComfortScore: Int
    ) -> Bool {
        if feelsLike < 5 { return false }
        if windImpact == .high { return false }
        if rainImpact == .moderate || rainImpact == .heavy { return false }
        if walkComfortScore < 60 { return false }
        return true
    }
}
