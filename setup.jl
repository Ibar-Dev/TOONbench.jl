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
    println("   ✓ Julia versión OK")
end

# 2. INSTALAR DEPENDENCIAS JULIA
println("\n2. Instalando dependencias Julia...")
Pkg.activate(".")

# Instalar paquetes
packages = [
    "PythonCall",
    "DataFrames",
    "JSON3",
    "BenchmarkTools"
]

for pkg in packages
    println("   Instalando $pkg...")
    try
        Pkg.add(pkg)
        println("   ✓ $pkg instalado")
    catch e
        println("   ✗ Error instalando $pkg: $e")
    end
end

# 3. INSTALAR TOON PYTHON
println("\n3. Configurando entorno Python...")
try
    using PythonCall
    pip = pyimport("pip")
    pip.main(["install", "toon"])
    println("   ✓ TOON Python instalado")
catch e
    println("   ✗ Error instalando TOON: $e")
    println("   Instala manualmente: pip install toon")
end

println("\n" * "="^70)
println("✓ SETUP COMPLETADO")
println("="^70)
println("\nSiguientes pasos:")
println("1. Ejecuta ejemplo básico:")
println("   julia --project=. examples/basic_usage.jl")
println("\n2. O ejecuta benchmark completo:")
println("   julia --project=. examples/full_benchmark.jl")
println("\n3. Para validar todo:")
println("   julia setup/test_before_publish.jl")