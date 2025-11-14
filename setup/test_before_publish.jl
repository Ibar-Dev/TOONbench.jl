# test_before_publish.jl
# Script de validación antes de publicar en GitHub
#
# Verifica que todos los componentes funcionen correctamente:
# 1. Dependencias instaladas
# 2. Generación de datos
# 3. Conversión TOON/JSON
# 4. Benchmarking
# 5. Reportes
#
# Ejecutar: julia --project=. test_before_publish.jl

using Pkg
Pkg.activate(".")

println("="^70)
println("VALIDACIÓN PRE-PUBLICACIÓN: TOONBench.jl")
println("="^70)
println()
println("Este script verifica que todos los componentes funcionen")
println("correctamente antes de publicar en GitHub.")
println()

# Contador de tests
tests_passed = 0
tests_failed = 0
test_results = []

function run_test(name::String, test_fn::Function)
    global tests_passed, tests_failed, test_results
    
    print("[$name] ")
    try
        test_fn()
        println("✓ PASS")
        tests_passed += 1
        push!(test_results, (name, "PASS", nothing))
        return true
    catch e
        println("✗ FAIL")
        println("   Error: ", e)
        tests_failed += 1
        push!(test_results, (name, "FAIL", e))
        return false
    end
end

println("Ejecutando tests...")
println("-"^70)
println()

# Cargar módulo para tests subsecuentes
include("../src/TOONBench.jl")
using .TOONBench

# TEST 1: Verificar que el módulo cargó
run_test("Cargar TOONBench.jl", () -> begin
    @assert isdefined(Main, :TOONBench)
    @assert isa(TOONBench, Module)
end)

# TEST 2: Generar series temporales
run_test("Generar series temporales") do
    data = generate_timeseries(10)
    @assert length(data) == 10
    @assert haskey(data[1], :timestamp)
end

# TEST 3: Generar matriz
run_test("Generar matriz") do
    data = generate_matrix_data(5, 10)
    @assert length(data) == 5
    @assert haskey(data[1], :values)
    @assert length(data[1][:values]) == 10
end

# TEST 4: Generar records
run_test("Generar experiment records") do
    data = generate_experiment_records(10, parameters=3)
    @assert length(data) == 10
    @assert haskey(data[1], :experiment_id)
end

# TEST 5: Inicializar Python
run_test("Inicializar entorno Python") do
    init_python_environment()
    @assert python_initialized[]
end

# TEST 6: Conversión a JSON
run_test("Conversión a JSON") do
    data = generate_timeseries(5)
    json_str = to_json(data)
    @assert length(json_str) > 0
    @assert occursin("timestamp", json_str)
end

# TEST 7: Conversión a TOON
run_test("Conversión a TOON") do
    data = generate_timeseries(5)
    toon_str = to_toon(data)
    @assert length(toon_str) > 0
    # TOON usa formato tabular
    @assert occursin("[", toon_str)  # Array notation
end

# TEST 8: Conteo de tokens
run_test("Conteo de tokens") do
    text = "Hello world, this is a test."
    tokens = count_tokens(text)
    @assert tokens > 0
    @assert tokens < 100  # Sanity check
end

# TEST 9: Comparación serialización
run_test("Comparación JSON vs TOON") do
    data = generate_timeseries(10)
    comparison = compare_serialization(data)
    
    @assert comparison.json_tokens > 0
    @assert comparison.toon_tokens > 0
    @assert comparison.json_tokens > comparison.toon_tokens  # TOON debe ser más eficiente
end

# TEST 10: Benchmark básico
run_test("Benchmark básico") do
    data = generate_timeseries(20)
    result = benchmark_formats(data, verbose=false)
    
    @assert result.json_tokens > 0
    @assert result.toon_tokens > 0
    @assert result.token_savings_percent >= 0
end

# TEST 11: BenchmarkConfig
run_test("Crear BenchmarkConfig") do
    config = BenchmarkConfig(
        dataset_sizes = [10, 20],
        data_types = [:timeseries],
        repetitions = 1,
        warmup = false
    )
    
    @assert length(config.dataset_sizes) == 2
    @assert config.repetitions == 1
end

# TEST 12: Generación de reporte (sin ejecutar benchmark completo)
run_test("Generar reporte HTML") do
    # Crear datos de prueba
    using DataFrames, Dates
    
    test_df = DataFrame(
        data_type = [:timeseries, :matrix],
        dataset_size = [100, 100],
        json_tokens = [1000, 1200],
        toon_tokens = [600, 700],
        token_savings_percent = [40.0, 41.7],
        json_time_ms = [10.0, 12.0],
        toon_time_ms = [15.0, 18.0],
        time_overhead_percent = [50.0, 50.0],
        json_memory_kb = [20.0, 25.0],
        toon_memory_kb = [22.0, 27.0],
        timestamp = [now(), now()]
    )
    
    mkpath("results")
    generate_report(test_df, "results/test_report.html")
    
    @assert isfile("results/test_report.html")
    
    # Verificar que el HTML contiene elementos clave
    html_content = read("results/test_report.html", String)
    @assert occursin("Benchmark TOON vs JSON", html_content)
    @assert occursin("timeseries", html_content)
    
    # Limpiar archivo de prueba
    rm("results/test_report.html")
end

# TEST 13: Archivos del proyecto existen
run_test("Verificar archivos del proyecto") do
    required_files = [
        "README.md",
        "LICENSE",
        "Project.toml",
        "setup.jl",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        ".gitignore",
        "src/TOONBench.jl",
        "src/data_generator.jl",
        "src/toon_converter.jl",
        "src/benchmarker.jl",
        "src/visualizer.jl",
        "examples/basic_usage.jl",
        "examples/full_benchmark.jl"
    ]
    
    for file in required_files
        @assert isfile(file) "$file no existe"
    end
end

# TEST 14: Project.toml válido
run_test("Validar Project.toml") do
    project = Pkg.TOML.parsefile("Project.toml")
    
    @assert haskey(project, "name")
    @assert project["name"] == "TOONBench"
    @assert haskey(project, "version")
    @assert haskey(project, "deps")
end

println()
println("="^70)
println("RESUMEN DE TESTS")
println("="^70)
println()
println("Total tests: ", tests_passed + tests_failed)
println("Passed: ", tests_passed, " ✓")
println("Failed: ", tests_failed, " ✗")
println()

if tests_failed > 0
    println("TESTS FALLIDOS:")
    println("-"^70)
    for (name, status, error) in test_results
        if status == "FAIL"
            println("  • $name")
            if error !== nothing
                println("    Error: $error")
            end
        end
    end
    println()
    println("⚠ CORRIJE LOS ERRORES ANTES DE PUBLICAR")
    exit(1)
else
    println("✓ TODOS LOS TESTS PASARON")
    println()
    println("="^70)
    println("CHECKLIST PRE-PUBLICACIÓN")
    println("="^70)
    println()
    println("Antes de publicar en GitHub, verifica:")
    println()
    println("[ ] Reemplazar placeholders:")
    println("    • [Tu Nombre] → Tu nombre real")
    println("    • [tuemail@ejemplo.com] → Tu email")
    println("    • tuusuario → Tu usuario de GitHub")
    println()
    println("[ ] Generar UUID real para Project.toml:")
    println("    using UUIDs; uuid4()")
    println()
    println("[ ] Actualizar README.md:")
    println("    • URLs correctas")
    println("    • Información de contacto")
    println()
    println("[ ] Ejecutar ejemplo básico:")
    println("    julia --project=. examples/basic_usage.jl")
    println()
    println("[ ] Leer GITHUB_SETUP.md para instrucciones de publicación")
    println()
    println("="^70)
    println()
    println("✓ El proyecto está listo para publicación técnica!")
    println("  Solo faltan los ajustes de personalización mencionados arriba.")
    println()
end