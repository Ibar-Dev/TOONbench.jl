# Changelog

All notable changes to TOONBench.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Sistema completo de benchmark para TOON vs JSON
- Generadores de datos científicos (series temporales, matrices, records)
- Integración con Python TOON via PythonCall.jl
- Sistema de reportes HTML con gráficos interactivos
- API modular con funciones de alto y bajo nivel

### Features
- `generate_timeseries()`: Generador de series temporales con timestamp y múltiples campos
- `generate_matrix_data()`: Generador de matrices numéricas para simulaciones
- `generate_experiment_records()`: Generador de records estructurados para experimentos
- `benchmark_formats()`: Comparación directa JSON vs TOON
- `run_full_benchmark()`: Benchmark completo con múltiples configuraciones
- `generate_report()`: Reportes HTML con visualizaciones
- `compare_serialization()`: Análisis detallado de serialización

### Dependencies
- PythonCall.jl: Integración Python-Julia
- DataFrames.jl: Manejo de datos tabulares
- JSON3.jl: Serialización JSON eficiente
- BenchmarkTools.jl: Mediciones de performance

## [0.1.0] - 2025-11-14

### Added
- Versión inicial de TOONBench.jl
- Implementación híbrida Julia+Python
- Validación de eficiencia TOON para datos científicos
- Documentación completa y ejemplos
- Tests de validación pre-publicación

### Highlights
- Primera implementación Julia-TOON para casos científicos
- Optimización para datasets uniformes (caso común en LLMs)
- Benchmarking exhaustivo de tokens, tiempo y memoria
- Reportes visuales profesionales

## Cambios Planeados (Roadmap)

### [0.2.0] - Próximo
- [ ] Soporte nativo para DataFrames.jl
- [ ] Integración con APIs LLM (OpenAI, Anthropic)
- [ ] Exportación a formato Parquet
- [ ] Dashboard interactivo con Pluto.jl

### [0.3.0] - Futuro
- [ ] Más tipos de datos científicos
- [ ] Optimizaciones adicionales
- [ ] Testing automático en CI/CD
- [ ] Documentación extendida con casos de uso reales

### [1.0.0] - Estable
- [ ] API estable y documentada
- [ ] Tests completos >95% cobertura
- [] Integraciones completas con ecosistema Julia
- [ ] Publicación en General Registry