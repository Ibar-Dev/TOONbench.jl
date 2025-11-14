# src/benchmarker.jl
# Sistema de benchmark para comparar performance JSON vs TOON
#
# Mide tres dimensiones clave:
# 1. Tokens: Cuántos tokens consume cada formato (costo LLM)
# 2. Tiempo: Velocidad de serialización
# 3. Memoria: Uso de memoria durante serialización
#
# Diseñado para benchmarks reproducibles con estadísticas robustas

using Statistics
using BenchmarkTools
using DataFrames
using Dates


"""
    BenchmarkConfig

Configuración para ejecutar un benchmark completo.

# Campos
- `dataset_sizes::Vector{Int}`: Tamaños de datasets a probar
- `data_types::Vector{Symbol}`: Tipos de datos (:timeseries, :matrix, :records)
- `repetitions::Int`: Número de repeticiones por configuración
- `warmup::Bool`: Si hacer warmup antes de medir (default: true)

# Ejemplo
```julia
config = BenchmarkConfig(
    dataset_sizes = [100, 1000, 10000],
    data_types = [:timeseries, :matrix, :records],
    repetitions = 5
)
```
"""
struct BenchmarkConfig
    dataset_sizes::Vector{Int}
    data_types::Vector{Symbol}
    repetitions::Int
    warmup::Bool
    
    # Constructor con valores por defecto
    function BenchmarkConfig(;
        dataset_sizes::Vector{Int} = [100, 1000, 10000],
        data_types::Vector{Symbol} = [:timeseries, :matrix, :records],
        repetitions::Int = 5,
        warmup::Bool = true
    )
        # Validaciones
        all(s -> s > 0, dataset_sizes) || throw(ArgumentError("dataset_sizes deben ser positivos"))
        repetitions > 0 || throw(ArgumentError("repetitions debe ser positivo"))
        
        new(dataset_sizes, data_types, repetitions, warmup)
    end
end


"""
    BenchmarkResult

Resultado de un benchmark individual (un tamaño + tipo de dato).

# Campos
- `data_type::Symbol`: Tipo de dato probado
- `dataset_size::Int`: Tamaño del dataset
- `json_tokens::Int`: Tokens del formato JSON
- `toon_tokens::Int`: Tokens del formato TOON
- `json_chars::Int`: Caracteres del formato JSON
- `toon_chars::Int`: Caracteres del formato TOON
- `json_time_ms::Float64`: Tiempo serialización JSON (ms)
- `toon_time_ms::Float64`: Tiempo serialización TOON (ms)
- `json_memory_kb::Float64`: Memoria usada JSON (KB)
- `toon_memory_kb::Float64`: Memoria usada TOON (KB)
- `token_savings_percent::Float64`: % ahorro en tokens
- `time_overhead_percent::Float64`: % overhead tiempo TOON vs JSON
- `timestamp::DateTime`: Momento del benchmark
"""
struct BenchmarkResult
    data_type::Symbol
    dataset_size::Int
    json_tokens::Int
    toon_tokens::Int
    json_chars::Int
    toon_chars::Int
    json_time_ms::Float64
    toon_time_ms::Float64
    json_memory_kb::Float64
    toon_memory_kb::Float64
    token_savings_percent::Float64
    time_overhead_percent::Float64
    timestamp::DateTime
end


"""
    generate_data_by_type(data_type::Symbol, size::Int)

Genera datos según el tipo especificado.

Función helper que encapsula la lógica de generación para
diferentes tipos de datos en el benchmark.

# Argumentos
- `data_type::Symbol`: Tipo (:timeseries, :matrix, :records, :experiments)
- `size::Int`: Tamaño del dataset

# Retorna
Vector de diccionarios con los datos generados
"""
function generate_data_by_type(data_type::Symbol, size::Int)
    if data_type == :timeseries
        return generate_timeseries(size, 
            fields = [:timestamp, :temperature, :pressure, :humidity]
        )
    elseif data_type == :matrix
        # Para matrices, size es número de filas, 50 columnas fijas
        return generate_matrix_data(size, 50)
    elseif data_type == :records
        return generate_experiment_records(size, parameters=5)
    elseif data_type == :experiments
        return generate_experiment_records(size, parameters=8)
    else
        throw(ArgumentError("Tipo de dato no soportado: $data_type"))
    end
end


"""
    benchmark_formats(data::Union{Dict, Vector}; verbose::Bool=true)

Ejecuta un benchmark completo comparando JSON vs TOON para un dataset.

Mide:
1. Tokens (usando tiktoken)
2. Tiempo de serialización (usando BenchmarkTools)
3. Memoria usada durante serialización

# Argumentos
- `data`: Dataset a benchmarkar
- `verbose`: Si mostrar progreso durante el benchmark

# Retorna
BenchmarkResult con todas las métricas

# Ejemplo
```julia
data = generate_timeseries(1000)
result = benchmark_formats(data)

println("Tokens JSON: ", result.json_tokens)
println("Tokens TOON: ", result.toon_tokens)
println("Ahorro: ", result.token_savings_percent, "%")
```

# Notas de Performance
- El benchmark usa @benchmark de BenchmarkTools para mediciones precisas
- Se ejecutan múltiples muestras y se calcula la mediana
- Incluye warmup automático para JIT compilation
"""
function benchmark_formats(data::Union{Dict, Vector}; verbose::Bool=true)
    verbose && println("Iniciando benchmark...")
    
    # Determinar tipo y tamaño del dataset
    dataset_size = data isa Vector ? length(data) : 1
    data_type = :unknown  # Se podría inferir del contenido
    
    # 1. MEDICIÓN DE TOKENS Y CARACTERES
    verbose && println("  → Serializando y contando tokens...")
    
    json_str = to_json(data, pretty=true)
    toon_str = to_toon(data)
    
    json_chars = length(json_str)
    toon_chars = length(toon_str)
    
    json_tokens = count_tokens(json_str)
    toon_tokens = count_tokens(toon_str)
    
    # 2. MEDICIÓN DE TIEMPO
    verbose && println("  → Midiendo tiempos de serialización...")
    
    # Benchmark JSON (multiple ejecuciones para precisión)
    json_bench = @benchmark to_json($data, pretty=true) samples=100
    json_time_ms = median(json_bench.times) / 1e6  # nanosegundos a milisegundos
    
    # Benchmark TOON
    toon_bench = @benchmark to_toon($data) samples=100
    toon_time_ms = median(toon_bench.times) / 1e6
    
    # 3. MEDICIÓN DE MEMORIA
    verbose && println("  → Midiendo uso de memoria...")
    
    json_memory_kb = json_bench.memory / 1024  # bytes a KB
    toon_memory_kb = toon_bench.memory / 1024
    
    # 4. CÁLCULO DE MÉTRICAS DERIVADAS
    token_savings = round((1 - toon_tokens / json_tokens) * 100, digits=2)
    time_overhead = round((toon_time_ms / json_time_ms - 1) * 100, digits=2)
    
    # Construir resultado
    result = BenchmarkResult(
        data_type,
        dataset_size,
        json_tokens,
        toon_tokens,
        json_chars,
        toon_chars,
        json_time_ms,
        toon_time_ms,
        json_memory_kb,
        toon_memory_kb,
        token_savings,
        time_overhead,
        now()
    )
    
    verbose && println("  ✓ Benchmark completado\n")
    
    return result
end


"""
    run_full_benchmark(config::BenchmarkConfig)

Ejecuta un benchmark exhaustivo según la configuración especificada.

Prueba todas las combinaciones de:
- Tamaños de dataset
- Tipos de datos
- Repeticiones

Genera estadísticas agregadas y permite análisis detallado.

# Retorna
DataFrame con una fila por configuración probada, columnas:
- data_type, dataset_size, repetition
- json_tokens, toon_tokens, token_savings_percent
- json_time_ms, toon_time_ms, time_overhead_percent
- json_memory_kb, toon_memory_kb
- timestamp

# Ejemplo
```julia
config = BenchmarkConfig(
    dataset_sizes = [100, 1000, 10000],
    data_types = [:timeseries, :records],
    repetitions = 3
)

results_df = run_full_benchmark(config)

# Analizar resultados
using Statistics
mean_savings = mean(results_df.token_savings_percent)
println("Ahorro promedio: ", mean_savings, "%")
```

# Duración Estimada
Para config por defecto (3 tamaños × 3 tipos × 5 reps = 45 benchmarks):
- Cada benchmark: ~5-10 segundos
- Total: ~4-8 minutos
"""
function run_full_benchmark(config::BenchmarkConfig)
    println("═"^70)
    println("BENCHMARK COMPLETO TOON vs JSON")
    println("═"^70)
    println("Configuración:")
    println("  - Tamaños: ", config.dataset_sizes)
    println("  - Tipos: ", config.data_types)
    println("  - Repeticiones: ", config.repetitions)
    println("  - Total benchmarks: ", length(config.dataset_sizes) * 
                                       length(config.data_types) * 
                                       config.repetitions)
    println("═"^70, "\n")
    
    # Warmup si está configurado
    if config.warmup
        println("Ejecutando warmup...")
        warmup_data = generate_timeseries(10)
        to_json(warmup_data)
        to_toon(warmup_data)
        println("✓ Warmup completado\n")
    end
    
    # Vector para almacenar todos los resultados
    all_results = BenchmarkResult[]
    
    # Contador para progreso
    total_benchmarks = length(config.dataset_sizes) * 
                       length(config.data_types) * 
                       config.repetitions
    current = 0
    
    # Iterar sobre todas las combinaciones
    for size in config.dataset_sizes
        for data_type in config.data_types
            for rep in 1:config.repetitions
                current += 1
                
                println("[$(current)/$total_benchmarks] Benchmarking: ",
                        "$data_type, size=$size, rep=$rep")
                
                # Generar datos
                data = generate_data_by_type(data_type, size)
                
                # Ejecutar benchmark
                result = benchmark_formats(data, verbose=false)
                
                # Actualizar data_type en resultado
                result_updated = BenchmarkResult(
                    data_type,
                    result.dataset_size,
                    result.json_tokens,
                    result.toon_tokens,
                    result.json_chars,
                    result.toon_chars,
                    result.json_time_ms,
                    result.toon_time_ms,
                    result.json_memory_kb,
                    result.toon_memory_kb,
                    result.token_savings_percent,
                    result.time_overhead_percent,
                    result.timestamp
                )
                
                push!(all_results, result_updated)
                
                # Mostrar resultado resumido
                println("    → Tokens: JSON=$(result.json_tokens), ",
                        "TOON=$(result.toon_tokens) ",
                        "(ahorro: $(result.token_savings_percent)%)")
                println()
            end
        end
    end
    
    println("═"^70)
    println("✓ BENCHMARK COMPLETADO")
    println("═"^70, "\n")
    
    # Convertir resultados a DataFrame
    df = DataFrame(
        data_type = [r.data_type for r in all_results],
        dataset_size = [r.dataset_size for r in all_results],
        json_tokens = [r.json_tokens for r in all_results],
        toon_tokens = [r.toon_tokens for r in all_results],
        token_savings_percent = [r.token_savings_percent for r in all_results],
        json_time_ms = [r.json_time_ms for r in all_results],
        toon_time_ms = [r.toon_time_ms for r in all_results],
        time_overhead_percent = [r.time_overhead_percent for r in all_results],
        json_memory_kb = [r.json_memory_kb for r in all_results],
        toon_memory_kb = [r.toon_memory_kb for r in all_results],
        timestamp = [r.timestamp for r in all_results]
    )
    
    # Mostrar resumen estadístico
    println("RESUMEN ESTADÍSTICO:")
    println("-"^70)
    println("Ahorro de tokens:")
    println("  Media: ", round(mean(df.token_savings_percent), digits=2), "%")
    println("  Mediana: ", round(median(df.token_savings_percent), digits=2), "%")
    println("  Mín-Máx: ", round(minimum(df.token_savings_percent), digits=2), "% - ",
                            round(maximum(df.token_savings_percent), digits=2), "%")
    println()
    println("Overhead de tiempo:")
    println("  Media: ", round(mean(df.time_overhead_percent), digits=2), "%")
    println("  Mediana: ", round(median(df.time_overhead_percent), digits=2), "%")
    println()
    
    return df
end


"""
    print_result_summary(result::BenchmarkResult)

Imprime un resumen legible del resultado de un benchmark.

# Ejemplo
```julia
result = benchmark_formats(data)
print_result_summary(result)
```
"""
function print_result_summary(result::BenchmarkResult)
    println("─"^70)
    println("RESULTADO BENCHMARK")
    println("─"^70)
    println("Dataset: ", result.data_type, " (", result.dataset_size, " registros)")
    println()
    println("TOKENS:")
    println("  JSON: ", result.json_tokens, " tokens")
    println("  TOON: ", result.toon_tokens, " tokens")
    println("  Ahorro: ", result.token_savings_percent, "%")
    println()
    println("TAMAÑO:")
    println("  JSON: ", result.json_chars, " caracteres")
    println("  TOON: ", result.toon_chars, " caracteres")
    println()
    println("TIEMPO:")
    println("  JSON: ", round(result.json_time_ms, digits=3), " ms")
    println("  TOON: ", round(result.toon_time_ms, digits=3), " ms")
    println("  Overhead: ", result.time_overhead_percent, "%")
    println()
    println("MEMORIA:")
    println("  JSON: ", round(result.json_memory_kb, digits=2), " KB")
    println("  TOON: ", round(result.toon_memory_kb, digits=2), " KB")
    println("─"^70)
end