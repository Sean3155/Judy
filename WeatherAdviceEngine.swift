import Foundation

struct WeatherAdviceEngine {
    
    static func generateAdvice(from weather: WeatherResponse) -> WeatherAdvice {
        let temp = weather.main.temp
        let feelsLike = weather.main.feelsLike
        let windSpeed = weather.wind.speed
        let description = weather.weather.first?.description.lowercased() ?? ""
        
        let comfort = determineComfortLevel(feelsLike: feelsLike)
        let windImpact = determineWindImpact(windSpeed: windSpeed)
        let rainImpact = determineRainImpact(description: description)
        
        let clothing = generateClothingRecommendations(
            temp: temp,
            feelsLike: feelsLike,
            windSpeed: windSpeed,
            rainImpact: rainImpact
        )
        
        let cautions = generateCautions(
            feelsLike: feelsLike,
            windImpact: windImpact,
            rainImpact: rainImpact,
            description: description
        )
        
        let summary = generateSummary(
            comfort: comfort,
            windImpact: windImpact,
            rainImpact: rainImpact
        )
        
        let comfortNote = generateComfortNote(
            feelsLike: feelsLike,
            windImpact: windImpact,
            rainImpact: rainImpact
        )
        
        let shortWalkOkay = isGoodForShortWalk(
            feelsLike: feelsLike,
            rainImpact: rainImpact
        )
        
        let longWalkOkay = isGoodForLongWalk(
            feelsLike: feelsLike,
            windImpact: windImpact,
            rainImpact: rainImpact
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
            isGoodForLongWalk: longWalkOkay
        )
    }
}

// MARK: - Core Logic
private extension WeatherAdviceEngine {
    
    static func determineComfortLevel(feelsLike: Double) -> ComfortLevel {
        switch feelsLike {
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
        if description.contains("thunderstorm") {
            return .heavy
        } else if description.contains("heavy rain") {
            return .heavy
        } else if description.contains("rain") {
            return .moderate
        } else if description.contains("drizzle") {
            return .light
        } else if description.contains("snow") {
            return .moderate
        } else {
            return .none
        }
    }
    
    static func generateClothingRecommendations(
        temp: Double,
        feelsLike: Double,
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
        
        if rainImpact == .moderate || rainImpact == .heavy {
            items.append("water-resistant outer layer")
        }
        
        if rainImpact == .light {
            items.append("consider a light umbrella")
        }
        
        return items
    }
    
    static func generateCautions(
        feelsLike: Double,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel,
        description: String
    ) -> [String] {
        var cautions: [String] = []
        
        if windImpact == .high {
            cautions.append("strong wind may mess up hair and loose clothing")
            cautions.append("hats may be annoying to keep on")
        } else if windImpact == .moderate {
            cautions.append("breeze may make it feel cooler than expected")
        }
        
        if rainImpact == .light {
            cautions.append("light rain may still be annoying without coverage")
        } else if rainImpact == .moderate || rainImpact == .heavy {
            cautions.append("getting wet is likely if you stay outside")
        }
        
        if feelsLike < 5 {
            cautions.append("it may feel colder than the raw temperature suggests")
        }
        
        if description.contains("snow") {
            cautions.append("watch for slippery ground")
        }
        
        return cautions
    }
    
    static func generateSummary(
        comfort: ComfortLevel,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel
    ) -> String {
        switch (comfort, windImpact, rainImpact) {
        case (.cold, .high, .none), (.cool, .high, .none):
            return "Not brutally cold, but the wind can make it pretty uncomfortable."
        case (.mild, .low, .none), (.warm, .low, .none):
            return "Overall, this is fairly comfortable weather."
        case (_, _, .moderate), (_, _, .heavy):
            return "The main issue today is less the temperature and more the wet conditions."
        case (.freezing, _, _):
            return "This is a genuinely cold day, so dress for warmth first."
        default:
            return "Conditions are manageable, but small details may affect comfort."
        }
    }
    
    static func generateComfortNote(
        feelsLike: Double,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel
    ) -> String {
        if rainImpact == .moderate || rainImpact == .heavy {
            return "A short trip may be fine, but staying outside for long could get uncomfortable fast."
        }
        
        if feelsLike < 8 && windImpact == .high {
            return "You might be okay for a quick walk, but longer outdoor time could feel rough."
        }
        
        if feelsLike >= 15 && windImpact == .low {
            return "For most people, this should feel pretty easy to deal with."
        }
        
        return "This should be okay in short bursts, depending on what you are wearing."
    }
    
    static func isGoodForShortWalk(
        feelsLike: Double,
        rainImpact: RainImpactLevel
    ) -> Bool {
        return feelsLike > -5 && rainImpact != .heavy
    }
    
    static func isGoodForLongWalk(
        feelsLike: Double,
        windImpact: WindImpactLevel,
        rainImpact: RainImpactLevel
    ) -> Bool {
        if feelsLike < 5 { return false }
        if windImpact == .high { return false }
        if rainImpact == .moderate || rainImpact == .heavy { return false }
        return true
    }
}
