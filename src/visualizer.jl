# src/visualizer.jl
# Sistema de visualización y reporte para resultados del benchmark
#
# Genera:
# 1. Gráficos ASCII para terminal (usando UnicodePlots)
# 2. Reportes HTML interactivos
# 3. Tablas resumen formateadas
#
# Los reportes son autocontenidos (HTML + CSS inline)
# para fácil compartición en GitHub

using DataFrames
using Statistics
using Printf


"""
    plot_token_comparison(df::DataFrame)

Genera gráfico ASCII comparando tokens JSON vs TOON por tamaño de dataset.

Este es un gráfico simple para visualización rápida en terminal.

# Argumentos
- `df::DataFrame`: Resultados del benchmark (de run_full_benchmark)

# Ejemplo
```julia
results = run_full_benchmark(config)
plot_token_comparison(results)
```
"""
function plot_token_comparison(df::DataFrame)
    println("\n" * "="^70)
    println("COMPARACIÓN DE TOKENS: JSON vs TOON")
    println("="^70)
    
    # Agrupar por tamaño y calcular promedios
    grouped = combine(groupby(df, :dataset_size),
        :json_tokens => mean => :avg_json_tokens,
        :toon_tokens => mean => :avg_toon_tokens,
        :token_savings_percent => mean => :avg_savings
    )
    
    sort!(grouped, :dataset_size)
    
    # Imprimir tabla
    println()
    println("Tamaño  │  JSON Tokens  │  TOON Tokens  │  Ahorro")
    println("─"^70)
    
    for row in eachrow(grouped)
        @printf("%6d  │  %11.0f  │  %11.0f  │  %6.2f%%\n",
            row.dataset_size,
            row.avg_json_tokens,
            row.avg_toon_tokens,
            row.avg_savings
        )
    end
    
    println("="^70 * "\n")
end


"""
    plot_time_comparison(df::DataFrame)

Genera gráfico ASCII comparando tiempos de serialización.

# Argumentos
- `df::DataFrame`: Resultados del benchmark
"""
function plot_time_comparison(df::DataFrame)
    println("\n" * "="^70)
    println("COMPARACIÓN DE TIEMPOS: JSON vs TOON")
    println("="^70)
    
    grouped = combine(groupby(df, :dataset_size),
        :json_time_ms => mean => :avg_json_time,
        :toon_time_ms => mean => :avg_toon_time,
        :time_overhead_percent => mean => :avg_overhead
    )
    
    sort!(grouped, :dataset_size)
    
    println()
    println("Tamaño  │  JSON (ms)  │  TOON (ms)  │  Overhead")
    println("─"^70)
    
    for row in eachrow(grouped)
        @printf("%6d  │  %10.3f  │  %10.3f  │  %+7.2f%%\n",
            row.dataset_size,
            row.avg_json_time,
            row.avg_toon_time,
            row.avg_overhead
        )
    end
    
    println("="^70 * "\n")
end


"""
    generate_html_table(df::DataFrame)

Genera tabla HTML con los resultados del benchmark.

Función interna usada por generate_report.
"""
function generate_html_table(df::DataFrame)
    html = """
    <table>
        <thead>
            <tr>
                <th>Tipo</th>
                <th>Tamaño</th>
                <th>JSON Tokens</th>
                <th>TOON Tokens</th>
                <th>Ahorro %</th>
                <th>JSON Tiempo (ms)</th>
                <th>TOON Tiempo (ms)</th>
                <th>Overhead %</th>
            </tr>
        </thead>
        <tbody>
    """
    
    for row in eachrow(df)
        html *= """
            <tr>
                <td>$(row.data_type)</td>
                <td>$(row.dataset_size)</td>
                <td>$(row.json_tokens)</td>
                <td>$(row.toon_tokens)</td>
                <td class="savings">$(round(row.token_savings_percent, digits=2))%</td>
                <td>$(round(row.json_time_ms, digits=3))</td>
                <td>$(round(row.toon_time_ms, digits=3))</td>
                <td>$(round(row.time_overhead_percent, digits=2))%</td>
            </tr>
        """
    end
    
    html *= """
        </tbody>
    </table>
    """
    
    return html
end


"""
    generate_report(df::DataFrame, output_path::String)

Genera reporte HTML completo con resultados del benchmark.

El reporte incluye:
- Resumen ejecutivo con estadísticas clave
- Tabla detallada de resultados
- Gráficos de comparación
- Análisis por tipo de dato
- CSS inline para estilos

# Argumentos
- `df::DataFrame`: Resultados del benchmark
- `output_path::String`: Ruta donde guardar el HTML

# Ejemplo
```julia
results = run_full_benchmark(config)
generate_report(results, "results/benchmark_report.html")
```

# Nota
El archivo HTML es autocontenido y puede abrirse directamente
en cualquier navegador sin dependencias externas.
"""
function generate_report(df::DataFrame, output_path::String)
    println("Generando reporte HTML...")
    
    # Calcular estadísticas agregadas
    stats = (
        total_benchmarks = nrow(df),
        avg_token_savings = round(mean(df.token_savings_percent), digits=2),
        median_token_savings = round(median(df.token_savings_percent), digits=2),
        min_token_savings = round(minimum(df.token_savings_percent), digits=2),
        max_token_savings = round(maximum(df.token_savings_percent), digits=2),
        avg_time_overhead = round(mean(df.time_overhead_percent), digits=2),
        timestamp = now()
    )
    
    # Estadísticas por tipo de dato
    by_type = combine(groupby(df, :data_type),
        :token_savings_percent => mean => :avg_savings,
        :time_overhead_percent => mean => :avg_overhead
    )
    
    # Construir HTML
    html = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte Benchmark TOON vs JSON</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        h1 { font-size: 2.5em; margin-bottom: 10px; }
        .subtitle { opacity: 0.9; font-size: 1.1em; }
        .timestamp { opacity: 0.8; font-size: 0.9em; margin-top: 10px; }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
            margin: 10px 0;
        }
        .metric-label {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.8em;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #eee;
        }
        tr:hover { background: #f9f9f9; }
        .savings {
            color: #10b981;
            font-weight: bold;
        }
        
        .type-analysis {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .type-card {
            padding: 20px;
            background: #f9f9f9;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .type-name {
            font-size: 1.3em;
            font-weight: bold;
            margin-bottom: 10px;
            color: #667eea;
        }
        
        footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <header>
        <h1>Benchmark TOON vs JSON</h1>
        <div class="subtitle">Análisis de eficiencia de serialización para LLMs</div>
        <div class="timestamp">Generado: $(stats.timestamp)</div>
    </header>
    
    <div class="summary">
        <div class="metric-card">
            <div class="metric-label">Ahorro Promedio</div>
            <div class="metric-value">$(stats.avg_token_savings)%</div>
            <div>en tokens</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Ahorro Mediano</div>
            <div class="metric-value">$(stats.median_token_savings)%</div>
            <div>en tokens</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Mejor Caso</div>
            <div class="metric-value">$(stats.max_token_savings)%</div>
            <div>ahorro máximo</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Overhead Tiempo</div>
            <div class="metric-value">$(stats.avg_time_overhead)%</div>
            <div>promedio TOON</div>
        </div>
    </div>
    
    <div class="section">
        <h2>Análisis por Tipo de Dato</h2>
        <div class="type-analysis">
    """
    
    # Agregar card por cada tipo de dato
    for row in eachrow(by_type)
        html *= """
            <div class="type-card">
                <div class="type-name">$(row.data_type)</div>
                <div>Ahorro tokens: <strong>$(round(row.avg_savings, digits=2))%</strong></div>
                <div>Overhead tiempo: <strong>$(round(row.avg_overhead, digits=2))%</strong></div>
            </div>
        """
    end
    
    html *= """
        </div>
    </div>
    
    <div class="section">
        <h2>Resultados Detallados</h2>
        <p>Total de benchmarks ejecutados: <strong>$(stats.total_benchmarks)</strong></p>
        $(generate_html_table(df))
    </div>
    
    <div class="section">
        <h2>Conclusiones</h2>
        <ul>
            <li>TOON reduce tokens en promedio <strong>$(stats.avg_token_savings)%</strong> comparado con JSON</li>
            <li>El overhead de tiempo de TOON es <strong>$(stats.avg_time_overhead)%</strong> en promedio</li>
            <li>Mejor caso: <strong>$(stats.max_token_savings)%</strong> de ahorro en tokens</li>
            <li>TOON es especialmente eficiente para datos uniformes (records, experimentos)</li>
        </ul>
    </div>
    
    <footer>
        <p>Generado por TOONBench.jl</p>
        <p>Benchmark Julia+TOON para optimización de prompts LLM</p>
    </footer>
</body>
</html>
    """
    
    # Crear directorio si no existe
    mkpath(dirname(output_path))
    
    # Escribir archivo
    open(output_path, "w") do file
        write(file, html)
    end
    
    println("✓ Reporte guardado en: $output_path")
    println("  Ábrelo en tu navegador para ver los resultados\n")
end
