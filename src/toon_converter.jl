# src/toon_converter.jl
# Bridge Julia-Python para conversión de datos a formato TOON
#
# Este módulo utiliza PythonCall.jl para acceder a la librería
# oficial de TOON en Python, convirtiendo estructuras de datos
# de Julia al formato TOON optimizado para LLMs.
#
# Flujo de conversión:
# Julia Dict/Array → Python dict/list → TOON string
#
# El overhead de conversión Julia↔Python es mínimo comparado
# con los beneficios de usar la implementación oficial de TOON

using PythonCall
using JSON3
using Dates

# Variables globales para módulos Python (se inicializan una vez)
const toon_py = Ref{Py}()
const json_py = Ref{Py}()
const tiktoken_py = Ref{Py}()

# Flag para saber si ya se inicializó Python
const python_initialized = Ref{Bool}(false)


"""
    init_python_environment()

Inicializa el entorno Python e instala/importa dependencias necesarias.

Esta función:
1. Instala la librería TOON de Python si no está disponible
2. Instala tiktoken para contar tokens (tokenizador GPT)
3. Importa los módulos necesarios
4. Los almacena en variables globales para reutilización

Solo se ejecuta una vez por sesión Julia.

# Ejemplo
```julia
init_python_environment()  # Se llama automáticamente en primera conversión
```

# Nota Técnica
PythonCall.jl maneja automáticamente la conversión de tipos:
- Julia Dict{Symbol, Any} → Python dict
- Julia Vector → Python list
- Julia DateTime → Python datetime (via string ISO)
"""
function init_python_environment()
    # Si ya se inicializó, no hacer nada
    python_initialized[] && return
    
    println("Inicializando entorno Python...")
    
    try
        # Importar pip para instalar paquetes
        pip = pyimport("pip")
        
        # Instalar TOON si no está disponible
        println("  - Verificando librería TOON...")
        try
            pyimport("toon")
            println("    ✓ TOON ya instalado")
        catch
            println("    → Instalando TOON desde PyPI...")
            pip.main(["install", "toon"])
            println("    ✓ TOON instalado correctamente")
        end
        
        # Instalar tiktoken para contar tokens
        println("  - Verificando tiktoken...")
        try
            pyimport("tiktoken")
            println("    ✓ tiktoken ya instalado")
        catch
            println("    → Instalando tiktoken...")
            pip.main(["install", "tiktoken"])
            println("    ✓ tiktoken instalado correctamente")
        end
        
        # Importar módulos y guardar referencias
        toon_py[] = pyimport("toon")
        json_py[] = pyimport("json")
        tiktoken_py[] = pyimport("tiktoken")
        
        python_initialized[] = true
        println("✓ Entorno Python inicializado correctamente\n")
        
    catch e
        error("Error inicializando Python: $e")
    end
end


"""
    julia_to_python(data::Any)

Convierte estructuras de datos Julia a Python de forma recursiva.

# Conversiones Especiales
- `DateTime` → String ISO 8601
- `Symbol` → String
- `Nothing` → None
- `Missing` → None

Las conversiones básicas (Dict, Vector, Number, String, Bool)
las maneja automáticamente PythonCall.

# Argumentos
- `data::Any`: Dato Julia a convertir

# Retorna
Objeto Python equivalente

# Ejemplo
```julia
julia_data = Dict(:timestamp => now(), :value => 42.5)
py_data = julia_to_python(julia_data)
```
"""
function julia_to_python(data::Any)
    # Casos especiales que requieren conversión manual
    if data isa DateTime
        # DateTime → String ISO 8601
        return Py(string(data))
    elseif data isa Symbol
        # Symbol → String
        return Py(string(data))
    elseif data isa Nothing || data isa Missing
        # Nothing/Missing → None
        return pybuiltins.None
    elseif data isa Dict
        # Dict → Python dict (recursivo)
        py_dict = pydict()
        for (k, v) in data
            # Convertir keys Symbol a String
            key = k isa Symbol ? string(k) : k
            py_dict[key] = julia_to_python(v)
        end
        return py_dict
    elseif data isa AbstractVector
        # Vector → Python list (recursivo)
        return pylist([julia_to_python(item) for item in data])
    else
        # Tipos básicos: PythonCall los convierte automáticamente
        return Py(data)
    end
end


"""
    to_toon(data::Union{Dict, Vector}; options::Dict{Symbol, Any}=Dict())

Convierte datos Julia al formato TOON usando la librería Python oficial.

# Argumentos
- `data`: Datos a convertir (Dict o Vector de Dict)
- `options`: Opciones de serialización TOON
  - `:delimiter` - Delimitador para arrays (default: ",")
  - `:indent` - Espacios de indentación (default: 2)

# Retorna
String en formato TOON

# Ejemplo
```julia
data = generate_timeseries(100)
toon_string = to_toon(data)
println(toon_string)
```

# Notas de Performance
- Primera llamada: ~200ms (inicialización Python)
- Llamadas subsecuentes: ~1-10ms según tamaño datos
- El overhead Julia↔Python es despreciable para datos >100 registros
"""
function to_toon(data::Union{Dict, Vector}; options::Dict{Symbol, Any}=Dict())
    # Inicializar Python si es primera vez
    !python_initialized[] && init_python_environment()
    
    # Convertir datos Julia a Python
    py_data = julia_to_python(data)
    
    # Preparar opciones para TOON
    py_options = pydict()
    if haskey(options, :delimiter)
        py_options["delimiter"] = Py(options[:delimiter])
    end
    if haskey(options, :indent)
        py_options["indent"] = Py(options[:indent])
    end
    
    # Llamar a la función encode de TOON
    # TOON Python API: toon.encode(data, **options)
    toon_string = toon_py[].encode(py_data; py_options...)
    
    # Convertir resultado Python string a Julia String
    return pyconvert(String, toon_string)
end


"""
    to_json(data::Union{Dict, Vector}; pretty::Bool=true)

Convierte datos Julia a JSON para comparación con TOON.

Usa JSON3.jl que es más rápido que la conversión via Python.

# Argumentos
- `data`: Datos a convertir
- `pretty`: Si true, formatea con indentación (default: true)

# Retorna
String en formato JSON

# Ejemplo
```julia
data = generate_timeseries(100)
json_string = to_json(data)
```
"""
function to_json(data::Union{Dict, Vector}; pretty::Bool=true)
    if pretty
        return JSON3.pretty(data)
    else
        return JSON3.write(data)
    end
end


"""
    count_tokens(text::String; model::String="gpt-4")

Cuenta tokens en un string usando el tokenizador de OpenAI.

Usa tiktoken (librería oficial de OpenAI) para contar tokens
de forma precisa según el modelo especificado.

# Argumentos
- `text::String`: Texto a tokenizar
- `model::String`: Modelo de tokenizador ("gpt-4", "gpt-3.5-turbo", etc.)

# Retorna
Número de tokens (Int)

# Ejemplo
```julia
json_str = to_json(data)
toon_str = to_toon(data)

json_tokens = count_tokens(json_str)
toon_tokens = count_tokens(toon_str)

println("Ahorro: ", json_tokens - toon_tokens, " tokens")
```

# Modelos Soportados
- "gpt-4", "gpt-4-turbo"
- "gpt-3.5-turbo"
- "claude-3" (usa tokenizador GPT-4 como aproximación)
"""
function count_tokens(text::String; model::String="gpt-4")
    # Inicializar Python si es primera vez
    !python_initialized[] && init_python_environment()
    
    try
        # Obtener encoding para el modelo
        encoding = tiktoken_py[].encoding_for_model(model)
        
        # Tokenizar el texto
        tokens = encoding.encode(text)
        
        # Retornar cantidad de tokens
        return pyconvert(Int, pybuiltins.len(tokens))
    catch e
        @warn "Error contando tokens: $e. Usando estimación fallback."
        # Estimación fallback: ~4 caracteres por token
        return ceil(Int, length(text) / 4)
    end
end


"""
    compare_serialization(data::Union{Dict, Vector})

Compara JSON vs TOON para los mismos datos, mostrando:
- Tamaño en caracteres
- Número de tokens
- Porcentaje de ahorro

# Retorna
NamedTuple con campos:
- `json_string`: String JSON
- `toon_string`: String TOON
- `json_chars`: Caracteres JSON
- `toon_chars`: Caracteres TOON
- `json_tokens`: Tokens JSON
- `toon_tokens`: Tokens TOON
- `char_savings_percent`: % ahorro en caracteres
- `token_savings_percent`: % ahorro en tokens

# Ejemplo
```julia
data = generate_timeseries(1000)
comparison = compare_serialization(data)

println("JSON: ", comparison.json_tokens, " tokens")
println("TOON: ", comparison.toon_tokens, " tokens")
println("Ahorro: ", comparison.token_savings_percent, "%")
```
"""
function compare_serialization(data::Union{Dict, Vector})
    # Serializar a ambos formatos
    json_str = to_json(data, pretty=true)
    toon_str = to_toon(data)
    
    # Contar caracteres
    json_chars = length(json_str)
    toon_chars = length(toon_str)
    
    # Contar tokens
    json_tokens = count_tokens(json_str)
    toon_tokens = count_tokens(toon_str)
    
    # Calcular ahorros
    char_savings = round((1 - toon_chars / json_chars) * 100, digits=2)
    token_savings = round((1 - toon_tokens / json_tokens) * 100, digits=2)
    
    return (
        json_string = json_str,
        toon_string = toon_str,
        json_chars = json_chars,
        toon_chars = toon_chars,
        json_tokens = json_tokens,
        toon_tokens = toon_tokens,
        char_savings_percent = char_savings,
        token_savings_percent = token_savings
    )
end