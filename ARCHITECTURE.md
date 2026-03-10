# Judy Architecture

## High Level System

The Judy app is structured as a modular SwiftUI application.

Each component has a clear responsibility.

Weather API → WeatherService → Weather Models → Advice Engine → Formatter → UI

---

# Core Components

## WeatherService

File:
WeatherService.swift

Responsibilities:

Fetch weather data from the OpenWeather API.

Tasks:

- network requests
- JSON decoding
- returning WeatherResponse models

---

## Weather Data Models

File:
WeatherData.swift

Contains models used to decode OpenWeather responses.

Models:

WeatherResponse  
WeatherInfo  
MainInfo  
WindInfo

Example structure:

WeatherResponse
├ name
├ weather[]
├ main
│   ├ temp
│   ├ feelsLike
└ wind
    ├ speed

---

## WeatherAdviceEngine

File:
WeatherAdviceEngine.swift

This is the core logic engine.

Input:
WeatherResponse

Output:
WeatherAdvice

Responsibilities:

- determine comfort level
- detect wind discomfort
- detect rain inconvenience
- generate clothing suggestions
- generate warnings
- evaluate walk comfort

---

## WeatherAdvice Model

File:
WeatherAdvice.swift

Structured result produced by the engine.

Example structure:

WeatherAdvice
├ comfortLevel
├ windImpact
├ rainImpact
├ clothingRecommendations
├ cautions
├ summary
├ comfortNote
├ isGoodForShortWalk
└ isGoodForLongWalk

This structured data allows the UI and chat system to reuse the same logic.

---

## AdviceFormatter

File:
AdviceFormatter.swift

Purpose:

Convert structured advice into natural language text.

Example:

"Not brutally cold, but the wind can make it pretty uncomfortable."

Different formats may exist for:

Home screen summary  
Chat explanation  
Voice responses

---

# UI Layer

SwiftUI based.

Main views:

HomeView  
ChatView  
SettingsView

---

## HomeView

Displays:

- current weather
- interpreted advice summary

Uses:

WeatherAdviceEngine  
AdviceFormatter

---

# Design Principles

## Separation of Concerns

Each system handles a single responsibility.

Weather fetching  
Weather interpretation  
Language formatting  
UI presentation

---

## Deterministic Advice Engine

The advice engine is rule based.

Benefits:

predictable  
fast  
debuggable  
no API cost

LLM models may enhance conversation but will not replace this core engine.

---

# Future Architecture

Planned system evolution:

Weather API
↓
WeatherService
↓
WeatherData
↓
WeatherAdviceEngine
↓
Structured Advice
↓
LLM Reasoning Layer
↓
Conversational Output

The deterministic engine remains the safety layer.
