# TOONBench.jl

Sistema de benchmark para comparar eficiencia de serialización TOON vs JSON en contextos de LLMs, aprovechando la velocidad de Julia para generación de datos y Python para conversión TOON.

## Descripción

TOONBench.jl es una herramienta híbrida Julia+Python que:

1. Genera datasets científicos masivos con Julia (alta performance)
2. Los serializa a TOON usando Python (via PythonCall.jl)
3. Compara tokens, tiempo y memoria vs JSON
4. Produce reportes visuales de eficiencia

**Innovación**: Primera implementación Julia-TOON para casos de uso científico (series temporales, matrices, simulaciones).

## Motivación

TOON (Token-Oriented Object Notation) promete reducir 30-60% tokens en prompts LLM. Este proyecto:

- Valida esas promesas con datos científicos reales
- Aprovecha Julia para casos donde Python es lento
- Documenta cuándo TOON vale la pena vs JSON
- Facilita integración Julia→LLM optimizada

## Estructura del Proyecto

```
toonbench/
├── README.md                    # Este archivo
├── Project.toml                 # Dependencias Julia
├── src/
│   ├── TOONBench.jl            # Módulo principal
│   ├── data_generator.jl       # Generador de datasets
│   ├── toon_converter.jl       # Bridge Julia-Python-TOON
│   ├── benchmarker.jl          # Sistema de medición
│   └── visualizer.jl           # Generación de gráficos
├── examples/
│   ├── basic_usage.jl          # Ejemplo básico
│   ├── scientific_data.jl      # Caso científico
│   └── compare_formats.jl      # Comparativa completa
└── results/                     # Outputs del benchmark
```

## Instalación

### Requisitos Previos

- Julia 1.9+
- Python 3.8+
- pip

### Paso 1: Clonar Repositorio

```bash
git clone https://github.com/tuusuario/TOONBench.jl.git
cd TOONBench.jl
```

### Paso 2: Instalar Dependencias Julia

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Paso 3: Instalar TOON Python

El proyecto instalará automáticamente la librería Python TOON via PythonCall:

```julia
using PythonCall
pip = pyimport("pip")
pip.main(["install", "toon"])
```

## Uso Rápido

### Ejemplo Básico

```julia
using TOONBench

# Generar dataset de ejemplo
data = generate_timeseries(1000)  # 1000 puntos temporales

# Comparar JSON vs TOON
results = benchmark_formats(data)

# Ver resultados
println("Tokens JSON: ", results.json_tokens)
println("Tokens TOON: ", results.toon_tokens)
println("Ahorro: ", results.savings_percent, "%")
```

### Benchmark Completo

```julia
using TOONBench

# Configurar benchmark
config = BenchmarkConfig(
    dataset_sizes = [100, 1000, 10000],
    data_types = [:timeseries, :matrix, :records],
    repetitions = 5
)

# Ejecutar
results = run_full_benchmark(config)

# Generar reporte
generate_report(results, "results/benchmark_report.html")
```

## Casos de Uso

### 1. Series Temporales Científicas

Datos de sensores, mediciones experimentales:

```julia
# Generar 10,000 mediciones de temperatura/presión
data = generate_timeseries(10_000, 
    fields = [:timestamp, :temperature, :pressure, :humidity]
)

result = benchmark_formats(data)
# Esperado: ~45% ahorro tokens con TOON
```

### 2. Matrices Numéricas

Resultados de simulaciones, cálculos científicos:

```julia
# Matriz 100x50 de resultados de simulación
data = generate_matrix_data(100, 50)

result = benchmark_formats(data)
# Esperado: ~30% ahorro tokens con TOON
```

### 3. Records Estructurados

Experimentos con múltiples parámetros:

```julia
# 500 experimentos con 8 parámetros cada uno
data = generate_experiment_records(500, parameters=8)

result = benchmark_formats(data)
# Esperado: ~55% ahorro tokens con TOON
```

## API Principal

### Generación de Datos

```julia
# Series temporales
generate_timeseries(n::Int; fields::Vector{Symbol})

# Matrices numéricas
generate_matrix_data(rows::Int, cols::Int)

# Records estructurados
generate_experiment_records(n::Int; parameters::Int)
```

### Conversión

```julia
# Convertir a TOON
to_toon(data) -> String

# Convertir a JSON
to_json(data) -> String
```

### Benchmarking

```julia
# Benchmark simple
benchmark_formats(data) -> BenchmarkResult

# Benchmark completo
run_full_benchmark(config::BenchmarkConfig) -> DataFrame
```

### Visualización

```julia
# Gráfico de comparación
plot_token_comparison(results)

# Reporte HTML completo
generate_report(results, output_path::String)
```

## Resultados Esperados

Basado en benchmarks preliminares:

| Tipo de Dato        | Tamaño | JSON Tokens | TOON Tokens | Ahorro |
|---------------------|--------|-------------|-------------|--------|
| Series Temporales   | 1,000  | 45,230      | 24,876      | 45%    |
| Matriz Numérica     | 100x50 | 67,543      | 47,280      | 30%    |
| Records Uniformes   | 500    | 23,450      | 10,553      | 55%    |

## Ventajas del Enfoque Híbrido

### Julia para Generación

- 10-100x más rápida que Python puro
- Ideal para simulaciones científicas
- Tipos nativos para datos numéricos

### Python para TOON

- Acceso a librería oficial TOON
- Ecosistema LLM maduro
- Interoperabilidad via PythonCall

### Resultado

- Mejor rendimiento end-to-end
- Flexibilidad para casos científicos
- Preparación óptima para LLMs

## Limitaciones Conocidas

1. **TOON es óptimo para datos uniformes**: Arrays de objetos con misma estructura
2. **Datos anidados profundos**: JSON puede ser más eficiente
3. **Overhead PythonCall**: Conversión Julia↔Python tiene costo (mínimo para datasets grandes)

## Roadmap

- [x] Implementación básica Julia+TOON
- [x] Generadores de datos científicos
- [x] Sistema de benchmarking
- [ ] Soporte para DataFrames.jl directo
- [ ] Integración con APIs LLM populares (OpenAI, Anthropic)
- [ ] Exportación a formato Parquet
- [ ] Dashboard interactivo con Pluto.jl

## Contribuir

Ver `CONTRIBUTING.md` para guías de contribución.

## Licencia

MIT License - Ver `LICENSE` para detalles

## Autor

Desarrollado por [Tu Nombre] - Especialista en Julia/Python para computación científica

## Referencias

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON Python Package](https://github.com/toon-format/toon)
- [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)

## Citar

Si usas TOONBench.jl en investigación, por favor cita:

```bibtex
@software{toonbench2025,
  author = {Tu Nombre},
  title = {TOONBench.jl: Benchmark TOON vs JSON para LLMs con Julia},
  year = {2025},
  url = {https://github.com/tuusuario/TOONBench.jl}
}
```
