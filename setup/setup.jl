# setup.jl
# Script de instalación y configuración inicial de TOONBench.jl
#
# Este script:
# 1. Verifica requisitos (Julia 1.9+)
# 2. Instala dependencias Julia
# 3. Configura entorno Python
# 4. Instala librería TOON
# 5. Ejecuta test básico
#
# Ejecutar: julia setup.jl

using Pkg
using InteractiveUtils

println("="^70)
println("SETUP: TOONBench.jl")
println("="^70)
println()

# 1. VERIFICAR VERSIÓN JULIA
println("1. Verificando versión de Julia...")
julia_version = VERSION
println("   Julia versión: $julia_version")

if julia_version < v"1.9"
    println("   ✗ ERROR: Se requiere Julia 1.9 o superior")
    println("   Descarga desde: https://julialang.org/downloads/")
    exit(1)
else
    println("   ✓ Versión compatible")
end
println()

# 2. ACTIVAR PROYECTO
println("2. Activando proyecto...")
Pkg.activate(".")
println("   ✓ Proyecto activado")
println()

# 3. INSTALAR DEPENDENCIAS JULIA
println("3. Instalando dependencias Julia...")
println("   (Esto puede tomar varios minutos la primera vez)")
println()

try
    Pkg.instantiate()
    println("   ✓ Dependencias Julia instaladas")
catch e
    println("   ✗ Error instalando dependencias: $e")
    exit(1)
end
println()

# 4. CONFIGURAR PYTHON
println("4. Configurando entorno Python...")

using PythonCall

try
    # Verificar pip
    pip = pyimport("pip")
    println("   ✓ pip disponible")
    
    # Instalar TOON
    println("   → Instalando librería TOON...")
    try
        pyimport("toon")
        println("   ✓ TOON ya instalado")
    catch
        pip.main(["install", "toon"])
        println("   ✓ TOON instalado correctamente")
    end
    
    # Instalar tiktoken
    println("   → Instalando tiktoken...")
    try
        pyimport("tiktoken")
        println("   ✓ tiktoken ya instalado")
    catch
        pip.main(["install", "tiktoken"])
        println("   ✓ tiktoken instalado correctamente")
    end
    
catch e
    println("   ✗ Error configurando Python: $e")
    println()
    println("   Solución:")
    println("   1. Instala Python 3.8+ desde python.org")
    println("   2. Ejecuta este script nuevamente")
    exit(1)
end
println()

# 5. TEST BÁSICO
println("5. Ejecutando test básico...")
println()

try
    # Cargar módulo
    include("src/TOONBench.jl")
    using .TOONBench
    
    # Generar datos pequeños
    println("   → Generando datos de prueba...")
    test_data = generate_timeseries(10)
    
    # Convertir a TOON
    println("   → Convirtiendo a TOON...")
    toon_str = to_toon(test_data)
    
    # Convertir a JSON
    println("   → Convirtiendo a JSON...")
    json_str = to_json(test_data)
    
    # Verificar que funcionó
    if length(toon_str) > 0 && length(json_str) > 0
        println("   ✓ Test básico exitoso")
    else
        println("   ✗ Test falló: conversión vacía")
        exit(1)
    end
    
catch e
    println("   ✗ Test falló: $e")
    exit(1)
end
println()

# 6. CREAR DIRECTORIO DE RESULTADOS
println("6. Creando directorios...")
mkpath("results")
println("   ✓ Directorio results/ creado")
println()

# 7. RESUMEN
println("="^70)
println("✓ SETUP COMPLETADO")
println("="^70)
println()
println("TOONBench.jl está listo para usar!")
println()
println("PRÓXIMOS PASOS:")
println()
println("1. Ejecuta el ejemplo básico:")
println("   julia --project=. examples/basic_usage.jl")
println()
println("2. O ejecuta un benchmark completo:")
println("   julia --project=. examples/full_benchmark.jl")
println()
println("3. Lee la documentación en README.md")
println()
println("="^70)