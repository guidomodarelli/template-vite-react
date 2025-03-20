#!/bin/bash

# Obtiene la raíz del repositorio con git
PROJECT_ROOT=$(git rev-parse --show-toplevel)

source "$PROJECT_ROOT/scripts/styleText.zsh"
source "$PROJECT_ROOT/scripts/fzf.zsh"

# Archivo de Docker Compose para el entorno de desarrollo
DOCKER_COMPOSE_FILE="compose.dev.yml"
DOCKER_COMPOSE_PATH="$(realpath $(dirname $0))/$DOCKER_COMPOSE_FILE"
export COMPOSE_BAKE=true

is_linux() {
    if uname -a | grep -iq "Linux"; then
        return 0 # true
    else
        return 1 # false
    fi
}

install_bun() {
    if is_linux; then
        curl -fsSL https://bun.sh/install | bash
    else
        powershell -c "irm bun.sh/install.ps1 | iex"
    fi
}

check_bun() {
    if ! command -v bun >/dev/null; then
        bun="$(logCyan -b bun)"
        logError "No se encontró el comando '$bun'."
        echo

        # Pregunta al usuario si desea instalar bun
        read -rp "¿Deseas instalar '$bun'? (s/n): " response
        if [[ "$response" =~ ^[SsYy]$ ]]; then
            install_bun
            return 0
        fi

        echo
        logInfo
        logInfo "Para instalar '$bun', ejecuta el siguiente comando:"
        logInfo
        logInfo "$(styleText -u -- "Linux"):"
        logInfo
        logInfo "  $(logCommand "curl -fsSL https://bun.sh/install | bash")"
        logInfo
        logInfo "$(styleText -u -- Windows):"
        logInfo
        logInfo "  $(logCommand "powershell -c \"irm bun.sh/install.ps1 | iex\"")"
        logInfo
        logInfo "Después de instalar '$bun', vuelve a ejecutar este script ($(logGreen -- $0))."
        logInfo
        exit 1
    fi
}

check_bun

commands() {
    {
        echo "  $(logCyan "build")   @ Construye la imagen de desarrollo"
        echo "  $(logCyan "up")      @ Inicia todos los servicios"
        echo "  $(logCyan "down")    @ Detiene y elimina los servicios y volúmenes"
        echo "  $(logCyan "start")   @ Inicia servicios detenidos"
        echo "  $(logCyan "stop")    @ Detiene los servicios sin eliminarlos"
        echo "  $(logCyan "restart") @ Reinicia todos los servicios"
        echo "  $(logCyan "lint")    @ Ejecuta el linter"
        echo "  $(logCyan "format")  @ Ejecuta el formateador de código"
        echo "  $(logCyan "check")   @ Ejecuta linter y formateador"
        echo "  $(logCyan "help")    @ Muestra esta ayuda"
    } | column -t -s "@"
}

# Función para mostrar cómo usar el script
function usage() {
    echo
    echo "$(styleText -u "Uso"): $0 COMANDO"
    echo
    echo "$(styleText -u "Comandos disponibles"):"
    commands
    exit 1
}

# Verifica si el archivo de Docker Compose existe
function check_docker_compose_file() {
    if [ ! -f "$DOCKER_COMPOSE_PATH" ]; then
        logError "No se encontró el archivo $(logCyan -u $DOCKER_COMPOSE_FILE) en la ruta $(logCyan -u "$(dirname $DOCKER_COMPOSE_PATH)")"
        exit 1
    fi
}

function docker_compose() {
    docker compose -f $DOCKER_COMPOSE_PATH "$@"
}

function docker_compose_dev() {
    docker_compose --profile dev "$@"
}

# Función para buildear la imagen de desarrollo
function build() {
    logInfo "Construyendo la imagen de desarrollo..."
    docker_compose_dev build
}

# Función para iniciar los servicios
function up() {
    logInfo "Iniciando los servicios con Docker Compose..."
    bun install
    docker_compose_dev up
}

# Función para detener y eliminar los servicios
function down() {
    logInfo "Deteniendo los servicios con Docker Compose..."
    docker_compose_dev down --volumes
}

# Función para iniciar los servicios detenidos
function start() {
    logInfo "Iniciando los servicios detenidos con Docker Compose..."
    docker_compose_dev start
}

# Función para detener los servicios sin eliminarlos
function stop() {
    logInfo "Deteniendo los servicios con Docker Compose..."
    docker_compose_dev stop
}

# Función para reiniciar los servicios
function restart() {
    logInfo "Reiniciando los servicios con Docker Compose..."
    docker_compose_dev restart
}

# Función para ejecutar el linter
function lint() {
    logInfo "Ejecutando linter con Docker Compose..."
    docker_compose up linter
}

# Función para ejecutar el formateo de código
function format() {
    logInfo "Ejecutando formateo de código con Docker Compose..."
    docker_compose up format
}

# Función para ejecutar ambos, lint y format
function check() {
    logInfo "Ejecutando linter y formateo de código con Docker Compose..."
    docker_compose --profile check up
}

# Función principal
function main() {
    # Verifica que el archivo docker-compose exista
    check_docker_compose_file

    # Verifica el primer parámetro y ejecuta el comando adecuado
    case "$1" in
    build)
        build
        ;;
    up)
        up
        ;;
    down)
        down
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    lint)
        lint
        ;;
    format)
        format
        ;;
    check)
        check
        ;;
    help)
        usage
        ;;
    *)
        logError "Comando no encontrado: '$(logCyan -b -- "$1")'"
        logInfo "Ejecutando el script interactivo..."
        if command -v fzf >/dev/null; then
            cmd=$(commands | fzf --header="Selecciona un comando con ENTER para confirmar" --prompt="Selecciona un comando > ")
            if [ -n "$cmd" ]; then
                main "$(echo "$cmd" | awk '{print $1}')"
            else
                usage
            fi
            exit 0
        fi
        usage
        ;;
    esac
}

# Llamada a la función principal
main "$1"
