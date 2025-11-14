# src/data_generator.jl
# Generador de datasets sintéticos para benchmark de serialización
# 
# Este módulo aprovecha la velocidad de Julia para generar grandes
# volúmenes de datos estructurados que simulan casos de uso reales:
# - Series temporales (sensores, mediciones)
# - Matrices numéricas (simulaciones, cálculos)
# - Records uniformes (experimentos, logs)
#
# La generación rápida en Julia permite benchmarks a gran escala
# sin que el tiempo de generación sea el cuello de botella

using Random
using Dates
using DataFrames

"""
    generate_timeseries(n::Int; fields::Vector{Symbol}=[:timestamp, :value])

Genera una serie temporal sintética con n puntos de datos.

# Argumentos
- `n::Int`: Número de puntos temporales a generar
- `fields::Vector{Symbol}`: Campos a incluir en cada punto (por defecto timestamp y value)

# Campos Soportados
- `:timestamp` - Timestamp ISO 8601
- `:value` - Valor numérico aleatorio
- `:temperature` - Temperatura en grados Celsius (-20 a 50)
- `:pressure` - Presión en hPa (980 a 1050)
- `:humidity` - Humedad relativa 0-100%
- `:sensor_id` - ID del sensor (entero)

# Retorna
Vector de diccionarios, cada uno representando un punto temporal.
Este formato es óptimo para TOON (array uniforme de objetos).

# Ejemplo
```julia
# Generar 1000 mediciones de temperatura y presión
data = generate_timeseries(1000, 
    fields = [:timestamp, :temperature, :pressure]
)
```

# Uso en Benchmark
Este tipo de dato es ideal para demostrar eficiencia de TOON:
- Estructura uniforme (mismos campos en cada registro)
- Tipos primitivos (números, strings)
- Alto volumen de registros

Esperado: 40-50% reducción de tokens vs JSON
"""
function generate_timeseries(n::Int; fields::Vector{Symbol}=[:timestamp, :value])
    # Validar número de puntos
    n <= 0 && throw(ArgumentError("n debe ser positivo, recibido: $n"))
    
    # Timestamp inicial: ahora menos n minutos
    start_time = now() - Minute(n)
    
    # Vector para almacenar todos los puntos
    data = Vector{Dict{Symbol, Any}}(undef, n)
    
    # Generar cada punto temporal
    for i in 1:n
        point = Dict{Symbol, Any}()
        
        # Procesar cada campo solicitado
        for field in fields
            if field == :timestamp
                # Timestamp incremental (1 minuto entre mediciones)
                point[:timestamp] = start_time + Minute(i-1)
            elseif field == :value
                # Valor genérico aleatorio
                point[:value] = round(randn() * 100 + 500, digits=2)
            elseif field == :temperature
                # Temperatura realista: -20 a 50°C con variación
                point[:temperature] = round(randn() * 10 + 20, digits=1)
            elseif field == :pressure
                # Presión atmosférica: 980-1050 hPa
                point[:pressure] = round(randn() * 20 + 1013, digits=1)
            elseif field == :humidity
                # Humedad relativa: 0-100%
                point[:humidity] = round(abs(randn()) * 30 + 50, digits=1)
                point[:humidity] = clamp(point[:humidity], 0, 100)
            elseif field == :sensor_id
                # ID de sensor (simulando múltiples sensores)
                point[:sensor_id] = rand(1:10)
            else
                # Campo no reconocido, usar valor genérico
                @warn "Campo no reconocido: $field, usando valor aleatorio"
                point[field] = rand()
            end
        end
        
        data[i] = point
    end
    
    return data
end


"""
    generate_matrix_data(rows::Int, cols::Int; sparse::Bool=false)

Genera datos matriciales simulando resultados de cálculos científicos.

# Argumentos
- `rows::Int`: Número de filas de la matriz
- `cols::Int`: Número de columnas de la matriz
- `sparse::Bool`: Si true, genera matriz sparse (muchos ceros)

# Retorna
Vector de diccionarios, cada uno con:
- `row_id`: Índice de fila
- `values`: Array de valores numéricos (columnas)

# Ejemplo
```julia
# Matriz 100x50 para simulación Monte Carlo
data = generate_matrix_data(100, 50)
```

# Uso en Benchmark
Las matrices son menos óptimas para TOON que series temporales,
pero siguen mostrando mejora vs JSON por la estructura uniforme.

Esperado: 25-35% reducción de tokens vs JSON
"""
function generate_matrix_data(rows::Int, cols::Int; sparse::Bool=false)
    # Validar dimensiones
    rows <= 0 && throw(ArgumentError("rows debe ser positivo"))
    cols <= 0 && throw(ArgumentError("cols debe ser positivo"))
    
    data = Vector{Dict{Symbol, Any}}(undef, rows)
    
    for i in 1:rows
        if sparse
            # Matriz sparse: 80% de ceros
            values = [rand() < 0.8 ? 0.0 : round(randn() * 10, digits=3) for _ in 1:cols]
        else
            # Matriz densa: valores aleatorios normales
            values = [round(randn() * 10, digits=3) for _ in 1:cols]
        end
        
        data[i] = Dict(
            :row_id => i,
            :values => values
        )
    end
    
    return data
end


"""
    generate_experiment_records(n::Int; parameters::Int=5)

Genera registros de experimentos científicos con múltiples parámetros.

# Argumentos
- `n::Int`: Número de experimentos
- `parameters::Int`: Número de parámetros por experimento

# Retorna
Vector de diccionarios, cada uno representando un experimento con:
- `experiment_id`: ID único del experimento
- `param_1` a `param_N`: Valores de parámetros
- `result`: Resultado del experimento
- `timestamp`: Momento del experimento
- `status`: Estado (success/failed)

# Ejemplo
```julia
# 500 experimentos con 8 parámetros cada uno
data = generate_experiment_records(500, parameters=8)
```

# Uso en Benchmark
Este es el caso óptimo para TOON:
- Alta uniformidad (todos los registros tienen mismos campos)
- Muchos registros
- Tipos primitivos

Esperado: 50-60% reducción de tokens vs JSON
"""
function generate_experiment_records(n::Int; parameters::Int=5)
    # Validar entradas
    n <= 0 && throw(ArgumentError("n debe ser positivo"))
    parameters <= 0 && throw(ArgumentError("parameters debe ser positivo"))
    
    data = Vector{Dict{Symbol, Any}}(undef, n)
    start_time = now() - Hour(n)
    
    for i in 1:n
        record = Dict{Symbol, Any}(
            :experiment_id => i,
            :timestamp => start_time + Hour(i-1),
            :status => rand(["success", "failed"]),
        )
        
        # Generar parámetros dinámicamente
        for p in 1:parameters
            param_name = Symbol("param_$p")
            record[param_name] = round(randn() * 100, digits=2)
        end
        
        # Resultado: suma ponderada de parámetros + ruido
        result = sum(get(record, Symbol("param_$p"), 0.0) for p in 1:parameters)
        record[:result] = round(result / parameters + randn() * 10, digits=2)
        
        data[i] = record
    end
    
    return data
end


"""
    generate_random_records(n::Int; schema::Dict{Symbol, Type})

Generador flexible para crear records con schema personalizado.

# Argumentos
- `n::Int`: Número de records
- `schema::Dict{Symbol, Type}`: Schema que mapea nombre_campo => tipo

# Tipos Soportados
- `Int`: Enteros aleatorios
- `Float64`: Flotantes aleatorios
- `String`: Strings aleatorios
- `Bool`: Booleanos aleatorios
- `DateTime`: Timestamps aleatorios

# Ejemplo
```julia
schema = Dict(
    :user_id => Int,
    :score => Float64,
    :active => Bool,
    :created_at => DateTime
)
data = generate_random_records(1000, schema=schema)
```
"""
function generate_random_records(n::Int; schema::Dict{Symbol, Type})
    n <= 0 && throw(ArgumentError("n debe ser positivo"))
    isempty(schema) && throw(ArgumentError("schema no puede estar vacío"))
    
    data = Vector{Dict{Symbol, Any}}(undef, n)
    
    for i in 1:n
        record = Dict{Symbol, Any}()
        
        for (field_name, field_type) in schema
            if field_type == Int
                record[field_name] = rand(1:1000)
            elseif field_type == Float64
                record[field_name] = round(randn() * 100, digits=2)
            elseif field_type == String
                # String aleatorio de 8 caracteres
                record[field_name] = randstring(8)
            elseif field_type == Bool
                record[field_name] = rand(Bool)
            elseif field_type == DateTime
                # DateTime en el último año
                record[field_name] = now() - Day(rand(1:365))
            else
                @warn "Tipo no soportado: $field_type para campo $field_name"
                record[field_name] = nothing
            end
        end
        
        data[i] = record
    end
    
    return data
end


"""
    data_to_dataframe(data::Vector{Dict{Symbol, Any}})

Convierte el vector de diccionarios a DataFrame de DataFrames.jl.

Útil para análisis posterior o exportación a otros formatos.

# Ejemplo
```julia
data = generate_timeseries(100)
df = data_to_dataframe(data)
```
"""
function data_to_dataframe(data::Vector{Dict{Symbol, Any}})
    isempty(data) && return DataFrame()
    return DataFrame(data)
end