# Judy Project Context

## Overview

Judy is a conversational AI weather assistant designed to translate raw weather data into practical real-world advice.

Unlike traditional weather apps that only display temperature and conditions, Judy explains how the weather will actually affect a person’s daily life.

Examples of questions Judy should answer:

- What should I wear today?
- Will wind ruin my hairstyle or outfit?
- Is it comfortable to take a short walk?
- Will rain be a small annoyance or a real problem?

Judy focuses on **weather interpretation**, not just weather display.

Core concept:

Weather Data → Interpretation → Human Advice

---

# Core Product Philosophy

Most weather apps stop at data.

Example:

Temperature: 13°C  
Wind: 8 m/s

But that doesn't answer the real question:

"Will I feel comfortable outside?"

Judy converts weather data into **human decisions**.

Example output:

"It’s not extremely cold, but the wind is strong enough that loose clothing or hats may get annoying."

---

# Current Tech Stack

Language:
Swift

UI Framework:
SwiftUI

Weather API:
OpenWeather API

Platform:
iOS

---

# Current App Structure

SwiftUI tab layout:

Home  
Chat  
Settings

HomeView displays current weather and advice.

ChatView will eventually allow conversational interaction with weather data.

---

# Weather Data Flow

Weather API  
↓  
WeatherService  
↓  
WeatherData Models  
↓  
WeatherAdviceEngine  
↓  
WeatherAdvice  
↓  
AdviceFormatter  
↓  
SwiftUI UI

---

# Advice Engine Purpose

The WeatherAdviceEngine is the core intelligence of the app.

It interprets weather conditions and generates structured advice.

Examples of interpretations:

Temperature → comfort level  
Wind speed → hair / clothing disruption  
Rain → umbrella usefulness  
Cold + wind → perceived discomfort  

---

# Advice Categories

The engine currently produces:

- comfort level
- wind impact
- rain impact
- clothing suggestions
- caution warnings
- short walk comfort
- long walk comfort
- summary advice

---

# Long Term Vision

Judy should eventually behave like a **personal weather advisor**.

Instead of checking a weather app, a user simply asks:

"Hey Judy, how’s the weather today?"

And receives a conversational explanation.

---

# Future Direction

Planned future capabilities:

User preference modeling  
Context based advice  
Conversational weather chat  
Voice interaction  
Outfit stability predictions  
Outdoor comfort modeling

---

# Development Priority

Current focus:

Improve the WeatherAdviceEngine.

Areas to expand:

humidity modeling  
UV exposure  
sunlight warmth effect  
wind gust impact  
precipitation probability  
ice / snow warnings

---

# Key Rule

Always translate weather data into real-world impact.

Weather data alone is not the final product.

The interpretation is the product.
