import Foundation

struct AdviceFormatter {
    
    static func homeCardText(from advice: WeatherAdvice) -> String {
        return advice.summary
    }
    
    static func detailedText(from advice: WeatherAdvice) -> String {
        var parts: [String] = []
        
        parts.append(advice.summary)
        parts.append(advice.comfortNote)
        
        if !advice.clothingRecommendations.isEmpty {
            let clothingLine = "What to wear: " + advice.clothingRecommendations.joined(separator: ", ") + "."
            parts.append(clothingLine)
        }
        
        if !advice.cautions.isEmpty {
            let cautionLine = "Watch out for: " + advice.cautions.joined(separator: ", ") + "."
            parts.append(cautionLine)
        }
        
        parts.append("Walk comfort score: \(advice.walkComfortScore)/100.")

        let walkLine = advice.isGoodForLongWalk
            ? "Longer walks should be pretty manageable."
            : (advice.isGoodForShortWalk
               ? "A short walk is probably fine, but a longer one may feel uncomfortable."
               : "Even a short walk could feel unpleasant unless you dress for it.")
        
        parts.append(walkLine)
        
        return parts.joined(separator: " ")
    }
}
