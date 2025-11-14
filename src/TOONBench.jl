

# src/TOONBench.jl
# Módulo principal del sistema de benchmark TOON vs JSON
# Este módulo coordina la generación de datos, conversión a formatos,
# medición de performance y visualización de resultados

module TOONBench

# Importar dependencias estándar de Julia
using DataFrames
using Dates
using Random
using BenchmarkTools
using JSON3

# Importar submódulos del proyecto
include("data_generator.jl")
include("toon_converter.jl")
include("benchmarker.jl")
include("visualizer.jl")

# Exportar funciones públicas para generación de datos
export generate_timeseries,
       generate_matrix_data,
       generate_experiment_records,
       generate_random_records

# Exportar funciones de conversión
export to_toon,
       to_json,
       compare_serialization

# Exportar funciones de benchmarking
export BenchmarkConfig,
       BenchmarkResult,
       benchmark_formats,
       run_full_benchmark

# Exportar funciones de visualización
export plot_token_comparison,
       plot_time_comparison,
       generate_report

# Función de bienvenida que muestra información del módulo
function __init__()
    println("TOONBench.jl v0.1.0 cargado")
    println("Benchmark Julia+TOON para optimización de prompts LLM")
    println("Use help(TOONBench) para documentación completa")
end

end # module TOONBench