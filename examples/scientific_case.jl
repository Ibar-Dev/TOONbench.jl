# examples/scientific_case.jl
# Caso de uso científico: Análisis de simulaciones Monte Carlo
#
# Este ejemplo demuestra cómo TOONBench puede ayudar en un
# flujo de trabajo científico real:
#
# 1. Ejecutar simulación computacionalmente intensiva (Julia)
# 2. Preparar resultados para análisis LLM
# 3. Comparar eficiencia JSON vs TOON
# 4. Estimar ahorro de costos en pipeline completo
#
# Ejecutar desde el directorio raíz:
# julia --project=. examples/scientific_case.jl

using Pkg
Pkg.activate(".")

# Importar TOONBench
include("src/TOONBench.jl")
using .TOONBench

using Random
using Statistics
using Dates

println("="^70)
println("CASO DE USO CIENTÍFICO: Simulación Monte Carlo")
println("="^70)
println()

# CONTEXTO DEL EXPERIMENTO
println("CONTEXTO:")
println("-"^70)
println("Simulación de difusión molecular con Monte Carlo")
println("Objetivo: Analizar 10,000 trayectorias con LLM para detectar patrones")
println()

# 1. SIMULACIÓN MONTE CARLO (aprovechando velocidad de Julia)
println("1. Ejecutando simulación Monte Carlo...")
println("   (Esto demuestra dónde Julia brilla: cálculos numéricos intensivos)")
println()

function monte_carlo_diffusion(n_particles::Int, n_steps::Int)
    """
    Simula difusión de partículas en 2D usando random walk.
    Esto es órdenes de magnitud más rápido en Julia que Python.
    """
    results = Vector{Dict{Symbol, Any}}(undef, n_particles)
    
    for i in 1:n_particles
        # Posición inicial
        x, y = 0.0, 0.0
        
        # Simular pasos
        for step in 1:n_steps
            # Random walk
            x += randn() * 0.1
            y += randn() * 0.1
        end
        
        # Calcular métricas finales
        distance = sqrt(x^2 + y^2)
        
        results[i] = Dict(
            :particle_id => i,
            :final_x => round(x, digits=3),
            :final_y => round(y, digits=3),
            :distance_from_origin => round(distance, digits=3),
            :n_steps => n_steps,
            :timestamp => now()
        )
    end
    
    return results
end

# Ejecutar simulación
n_particles = 1000
n_steps = 10000

println("   Simulando $n_particles partículas, $n_steps pasos cada una...")
@time simulation_data = monte_carlo_diffusion(n_particles, n_steps)
println("   ✓ Simulación completada")
println()

# 2. PREPARAR PROMPT PARA LLM
println("2. Preparando datos para análisis LLM...")
println()

# Imaginemos que queremos enviar estos datos a un LLM para que:
# - Detecte outliers en las trayectorias
# - Identifique patrones anómalos
# - Sugiera hipótesis sobre la difusión

prompt_template = """
Analiza los siguientes resultados de simulación Monte Carlo de difusión molecular.

DATOS:
{{SIMULATION_DATA}}

TAREAS:
1. Identifica las 5 partículas con mayor distancia recorrida
2. Detecta patrones anómalos en la distribución
3. Calcula estadísticas descriptivas
4. Sugiere posibles causas de outliers

Responde en formato estructurado.
"""

# 3. COMPARAR JSON VS TOON
println("3. Comparando eficiencia de serialización...")
println()

comparison = compare_serialization(simulation_data)

# 4. ANÁLISIS DE RESULTADOS
println("="^70)
println("RESULTADOS DE LA COMPARACIÓN")
println("="^70)
println()

println("TAMAÑO DEL PROMPT:")
println("  Prompt base: ", length(prompt_template), " caracteres")
println("  + Datos JSON: ", comparison.json_chars, " caracteres")
println("  + Datos TOON: ", comparison.toon_chars, " caracteres")
println()
println("  Total con JSON: ", length(prompt_template) + comparison.json_chars, " caracteres")
println("  Total con TOON: ", length(prompt_template) + comparison.toon_chars, " caracteres")
println()

println("TOKENS (Costo Real):")
println("  JSON: ", comparison.json_tokens, " tokens")
println("  TOON: ", comparison.toon_tokens, " tokens")
println("  Ahorro: ", comparison.token_savings_percent, "%")
println("  Tokens ahorrados: ", comparison.json_tokens - comparison.toon_tokens, " tokens")
println()

# 5. PROYECCIÓN DE COSTOS
println("="^70)
println("PROYECCIÓN DE COSTOS EN PIPELINE CIENTÍFICO")
println("="^70)
println()

# Supongamos un flujo de trabajo típico:
experiments_per_day = 50
days_per_month = 30
cost_per_million_input_tokens = 3.0  # USD (ejemplo GPT-4)
cost_per_million_output_tokens = 15.0  # USD (generación más cara)

# Tokens de entrada
input_tokens_json = comparison.json_tokens
input_tokens_toon = comparison.toon_tokens
tokens_saved_per_experiment = input_tokens_json - input_tokens_toon

# Estimación tokens de salida (asumimos respuesta ~500 tokens)
output_tokens_per_experiment = 500

# Cálculos mensuales
monthly_experiments = experiments_per_day * days_per_month
monthly_input_tokens_json = input_tokens_json * monthly_experiments / 1_000_000
monthly_input_tokens_toon = input_tokens_toon * monthly_experiments / 1_000_000
monthly_output_tokens = output_tokens_per_experiment * monthly_experiments / 1_000_000

# Costos mensuales
cost_input_json = monthly_input_tokens_json * cost_per_million_input_tokens
cost_input_toon = monthly_input_tokens_toon * cost_per_million_input_tokens
cost_output = monthly_output_tokens * cost_per_million_output_tokens

total_cost_json = cost_input_json + cost_output
total_cost_toon = cost_input_toon + cost_output
monthly_savings = total_cost_json - total_cost_toon
annual_savings = monthly_savings * 12

println("ESCENARIO:")
println("  - Experimentos por día: $experiments_per_day")
println("  - Experimentos por mes: $monthly_experiments")
println("  - Costo input: \$$cost_per_million_input_tokens / 1M tokens")
println("  - Costo output: \$$cost_per_million_output_tokens / 1M tokens")
println()

println("COSTOS MENSUALES:")
println("  Con JSON:")
println("    • Input:  \$", round(cost_input_json, digits=2))
println("    • Output: \$", round(cost_output, digits=2))
println("    • Total:  \$", round(total_cost_json, digits=2))
println()
println("  Con TOON:")
println("    • Input:  \$", round(cost_input_toon, digits=2))
println("    • Output: \$", round(cost_output, digits=2))
println("    • Total:  \$", round(total_cost_toon, digits=2))
println()

println("AHORRO:")
println("  • Por mes:  \$", round(monthly_savings, digits=2))
println("  • Por año:  \$", round(annual_savings, digits=2))
println("  • Porcentaje: ", round((monthly_savings / total_cost_json) * 100, digits=2), "%")
println()

# 6. BENEFICIOS ADICIONALES
println("="^70)
println("BENEFICIOS ADICIONALES DE USAR JULIA+TOON")
println("="^70)
println()

println("1. VELOCIDAD DE SIMULACIÓN (Julia):")
println("   • Monte Carlo en Julia: ~10-100x más rápido que Python")
println("   • Permite más experimentos en menos tiempo")
println("   • Mejor uso de recursos computacionales")
println()

println("2. EFICIENCIA DE PROMPTS (TOON):")
println("   • $(comparison.token_savings_percent)% menos tokens")
println("   • Menor costo por experimento")
println("   • Más contexto disponible en ventana de LLM")
println()

println("3. WORKFLOW INTEGRADO:")
println("   • Cálculos pesados → Julia")
println("   • Serialización optimizada → TOON")
println("   • Análisis inteligente → LLM")
println()

# 7. VISUALIZAR MUESTRA DE DATOS
println("="^70)
println("MUESTRA DE DATOS (primeros 5 registros)")
println("="^70)
println()

println("FORMATO TOON:")
println("-"^70)
sample_toon = to_toon(simulation_data[1:5])
println(sample_toon)
println()

# 8. CONCLUSIONES
println("="^70)
println("CONCLUSIONES")
println("="^70)
println()

println("Para este pipeline científico:")
println()
println("  ✓ Julia acelera la simulación 10-100x")
println("  ✓ TOON reduce tokens $(comparison.token_savings_percent)%")
println("  ✓ Ahorro anual estimado: \$$(round(annual_savings, digits=2))")
println()
println("El enfoque híbrido Julia+TOON+LLM permite:")
println("  • Simulaciones más rápidas")
println("  • Análisis más económico")
println("  • Mayor escala de experimentación")
println()

println("RECOMENDACIÓN:")
if annual_savings > 1000
    println("  ✓ Ahorro significativo, implementación altamente recomendada")
elseif annual_savings > 100
    println("  ✓ Ahorro notable, implementación recomendada")
else
    println("  • Ahorro moderado, evaluar según volumen de uso")
end
println()
println("="^70)