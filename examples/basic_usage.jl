# examples/basic_usage.jl
# Ejemplo básico de uso de TOONBench.jl
#
# Este script demuestra el uso fundamental del sistema:
# 1. Generar datos científicos
# 2. Compararlos en formato JSON vs TOON
# 3. Analizar el ahorro en tokens
#
# Ejecutar desde el directorio raíz:
# julia --project=. examples/basic_usage.jl

using Pkg
Pkg.activate(".")

# Importar TOONBench
include("src/TOONBench.jl")
using .TOONBench

println("="^70)
println("EJEMPLO BÁSICO: TOONBench.jl")
println("="^70)
println()

# 1. GENERAR DATOS DE EJEMPLO
println("1. Generando datos de series temporales...")
println("   (1000 puntos con temperatura, presión y humedad)")
println()

data = generate_timeseries(1000, 
    fields = [:timestamp, :temperature, :pressure, :humidity]
)

println("✓ Datos generados: ", length(data), " registros")
println()

# 2. COMPARAR JSON VS TOON
println("2. Comparando serialización JSON vs TOON...")
println()

comparison = compare_serialization(data)

# 3. MOSTRAR RESULTADOS
println("="^70)
println("RESULTADOS DE LA COMPARACIÓN")
println("="^70)
println()

println("TAMAÑO EN CARACTERES:")
println("  JSON: ", comparison.json_chars, " caracteres")
println("  TOON: ", comparison.toon_chars, " caracteres")
println("  Ahorro: ", comparison.char_savings_percent, "%")
println()

println("TOKENS (Costo LLM):")
println("  JSON: ", comparison.json_tokens, " tokens")
println("  TOON: ", comparison.toon_tokens, " tokens")
println("  Ahorro: ", comparison.token_savings_percent, "%")
println()

# 4. CALCULAR AHORRO ECONÓMICO
println("AHORRO ECONÓMICO ESTIMADO:")
tokens_saved = comparison.json_tokens - comparison.toon_tokens
cost_per_million_tokens = 3.0  # USD por millón de tokens (ejemplo GPT-4)
cost_savings = (tokens_saved / 1_000_000) * cost_per_million_tokens

println("  Si envías estos datos 1000 veces al mes:")
println("  Tokens ahorrados: ", tokens_saved * 1000, " tokens/mes")
println("  Dinero ahorrado: \$", round(cost_savings * 1000, digits=2), " USD/mes")
println()

# 5. MOSTRAR FRAGMENTO DE CADA FORMATO
println("="^70)
println("VISTA PREVIA DE FORMATOS (primeros 500 caracteres)")
println("="^70)
println()

println("JSON:")
println("-"^70)
println(comparison.json_string[1:min(500, end)])
println("...")
println()

println("TOON:")
println("-"^70)
println(comparison.toon_string[1:min(500, end)])
println("...")
println()

# 6. CONCLUSIÓN
println("="^70)
println("CONCLUSIÓN")
println("="^70)
println()
println("Para este dataset de series temporales:")
println("  • TOON reduce $(comparison.token_savings_percent)% de tokens")
println("  • Esto se traduce en menor costo de API LLM")
println("  • La legibilidad se mantiene alta")
println()
println("TOON es especialmente efectivo para:")
println("  ✓ Arrays uniformes de objetos")
println("  ✓ Datos científicos estructurados")
println("  ✓ Logs y registros con mismo schema")
println()
println("="^70)