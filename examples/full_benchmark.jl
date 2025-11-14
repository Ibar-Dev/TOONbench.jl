# examples/full_benchmark.jl
# Ejemplo de benchmark completo con TOONBench.jl
#
# Este script ejecuta un benchmark exhaustivo:
# 1. Múltiples tamaños de datasets
# 2. Múltiples tipos de datos
# 3. Repeticiones para estadísticas robustas
# 4. Generación de reporte HTML
#
# ADVERTENCIA: Este benchmark puede tomar varios minutos
# Ejecutar desde el directorio raíz:
# julia --project=. examples/full_benchmark.jl

using Pkg
Pkg.activate(".")

# Importar TOONBench
include("src/TOONBench.jl")
using .TOONBench

println("="^70)
println("BENCHMARK COMPLETO: TOONBench.jl")
println("="^70)
println()
println("Este benchmark ejecutará múltiples pruebas para evaluar")
println("la eficiencia de TOON vs JSON en diferentes escenarios.")
println()

# Preguntar al usuario si continuar
print("¿Continuar? (s/n): ")
response = readline()
if lowercase(response) != "s"
    println("Benchmark cancelado.")
    exit(0)
end

println()

# 1. CONFIGURAR BENCHMARK
println("1. Configurando benchmark...")
println()

config = BenchmarkConfig(
    # Tamaños progresivos: pequeño, mediano, grande
    dataset_sizes = [100, 1000, 5000],
    
    # Tipos de datos científicos
    data_types = [:timeseries, :matrix, :records],
    
    # 3 repeticiones para estadísticas
    repetitions = 3,
    
    # Warmup habilitado
    warmup = true
)

println("Configuración:")
println("  - Tamaños: ", config.dataset_sizes)
println("  - Tipos: ", config.data_types)
println("  - Repeticiones: ", config.repetitions)
println("  - Total pruebas: ", length(config.dataset_sizes) * 
                                 length(config.data_types) * 
                                 config.repetitions)
println()
println("Tiempo estimado: 3-5 minutos")
println()

# 2. EJECUTAR BENCHMARK
println("2. Ejecutando benchmark...")
println()

results_df = run_full_benchmark(config)

# 3. ANÁLISIS DE RESULTADOS
println()
println("3. Analizando resultados...")
println()

# Agrupar por tipo de dato
using Statistics
by_type = combine(groupby(results_df, :data_type),
    :token_savings_percent => mean => :avg_savings,
    :token_savings_percent => std => :std_savings,
    :time_overhead_percent => mean => :avg_overhead
)

println("RESULTADOS POR TIPO DE DATO:")
println("-"^70)
for row in eachrow(by_type)
    println("$(row.data_type):")
    println("  Ahorro tokens: $(round(row.avg_savings, digits=2))% ",
            "(±$(round(row.std_savings, digits=2))%)")
    println("  Overhead tiempo: $(round(row.avg_overhead, digits=2))%")
    println()
end

# Análisis por tamaño
by_size = combine(groupby(results_df, :dataset_size),
    :token_savings_percent => mean => :avg_savings,
    :json_tokens => mean => :avg_json_tokens,
    :toon_tokens => mean => :avg_toon_tokens
)

println("RESULTADOS POR TAMAÑO:")
println("-"^70)
for row in eachrow(sort(by_size, :dataset_size))
    println("Tamaño $(row.dataset_size):")
    println("  JSON: $(round(Int, row.avg_json_tokens)) tokens")
    println("  TOON: $(round(Int, row.avg_toon_tokens)) tokens")
    println("  Ahorro: $(round(row.avg_savings, digits=2))%")
    println()
end

# 4. GENERAR VISUALIZACIONES
println("4. Generando visualizaciones...")
println()

plot_token_comparison(results_df)
plot_time_comparison(results_df)

# 5. GENERAR REPORTE HTML
println("5. Generando reporte HTML...")
println()

# Crear directorio de resultados si no existe
mkpath("results")

# Generar reporte con timestamp
timestamp = Dates.format(now(), "yyyy-mm-dd_HHMMSS")
report_path = "results/benchmark_report_$timestamp.html"

generate_report(results_df, report_path)

# 6. GUARDAR DATOS CRUDOS
println("6. Guardando datos crudos...")
println()

# Guardar DataFrame a CSV para análisis posterior
using CSV
csv_path = "results/benchmark_data_$timestamp.csv"
CSV.write(csv_path, results_df)
println("✓ Datos guardados en: $csv_path")
println()

# 7. RESUMEN FINAL
println("="^70)
println("BENCHMARK COMPLETADO")
println("="^70)
println()

total_benchmarks = nrow(results_df)
avg_savings = round(mean(results_df.token_savings_percent), digits=2)
max_savings = round(maximum(results_df.token_savings_percent), digits=2)
avg_overhead = round(mean(results_df.time_overhead_percent), digits=2)

println("RESUMEN:")
println("  • Total pruebas: $total_benchmarks")
println("  • Ahorro promedio: $avg_savings%")
println("  • Mejor caso: $max_savings%")
println("  • Overhead tiempo promedio: $avg_overhead%")
println()

println("ARCHIVOS GENERADOS:")
println("  • Reporte HTML: $report_path")
println("  • Datos CSV: $csv_path")
println()

println("RECOMENDACIONES:")
println()
if avg_savings > 40
    println("  ✓ TOON muestra excelente eficiencia para tus datos")
    println("  ✓ Recomendado para reducir costos LLM significativamente")
elseif avg_savings > 25
    println("  ✓ TOON muestra buena eficiencia para tus datos")
    println("  ✓ Considerar para casos de alto volumen")
else
    println("  ⚠ TOON muestra eficiencia moderada")
    println("  ⚠ Evaluar trade-off según tu caso de uso")
end

if avg_overhead < 50
    println("  ✓ Overhead de tiempo es aceptable")
elseif avg_overhead < 100
    println("  ⚠ Overhead de tiempo es notable pero razonable")
else
    println("  ⚠ Overhead de tiempo es significativo")
    println("  ⚠ Considerar solo si ahorro de tokens es crítico")
end

println()
println("="^70)
println()
println("Para ver el reporte completo, abre en tu navegador:")
println("  $report_path")
println()