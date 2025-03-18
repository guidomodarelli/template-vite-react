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
        bun="$(printCyan -b bun)"
        printError "No se encontró el comando '$bun'."
        echo

        # Pregunta al usuario si desea instalar bun
        read -rp "¿Deseas instalar '$bun'? (s/n): " response
        if [[ "$response" =~ ^[SsYy]$ ]]; then
            install_bun
            return 0
        fi

        echo
        printInfo
        printInfo "Para instalar '$bun', ejecuta el siguiente comando:"
        printInfo
        printInfo "$(styleText -u -- "Linux"):"
        printInfo
        printInfo "  $(printCommand "curl -fsSL https://bun.sh/install | bash")"
        printInfo
        printInfo "$(styleText -u -- Windows):"
        printInfo
        printInfo "  $(printCommand "powershell -c \"irm bun.sh/install.ps1 | iex\"")"
        printInfo
        printInfo "Después de instalar '$bun', vuelve a ejecutar este script ($(printGreen -- $0))."
        printInfo
        exit 1
    fi
}

check_bun

commands() {
    {
        echo "  $(printCyan "build")   @ Construye la imagen de desarrollo"
        echo "  $(printCyan "up")      @ Inicia todos los servicios"
        echo "  $(printCyan "down")    @ Detiene y elimina los servicios y volúmenes"
        echo "  $(printCyan "start")   @ Inicia servicios detenidos"
        echo "  $(printCyan "stop")    @ Detiene los servicios sin eliminarlos"
        echo "  $(printCyan "restart") @ Reinicia todos los servicios"
        echo "  $(printCyan "lint")    @ Ejecuta el linter"
        echo "  $(printCyan "format")  @ Ejecuta el formateador de código"
        echo "  $(printCyan "check")   @ Ejecuta linter y formateador"
        echo "  $(printCyan "help")    @ Muestra esta ayuda"
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
        printError "No se encontró el archivo $(printCyan -u $DOCKER_COMPOSE_FILE) en la ruta $(printCyan -u "$(dirname $DOCKER_COMPOSE_PATH)")"
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
    printInfo "Construyendo la imagen de desarrollo..."
    docker_compose_dev build
}

# Función para iniciar los servicios
function up() {
    printInfo "Iniciando los servicios con Docker Compose..."
    bun install
    docker_compose_dev up
}

# Función para detener y eliminar los servicios
function down() {
    printInfo "Deteniendo los servicios con Docker Compose..."
    docker_compose_dev down --volumes
}

# Función para iniciar los servicios detenidos
function start() {
    printInfo "Iniciando los servicios detenidos con Docker Compose..."
    docker_compose_dev start
}

# Función para detener los servicios sin eliminarlos
function stop() {
    printInfo "Deteniendo los servicios con Docker Compose..."
    docker_compose_dev stop
}

# Función para reiniciar los servicios
function restart() {
    printInfo "Reiniciando los servicios con Docker Compose..."
    docker_compose_dev restart
}

# Función para ejecutar el linter
function lint() {
    printInfo "Ejecutando linter con Docker Compose..."
    docker_compose up linter
}

# Función para ejecutar el formateo de código
function format() {
    printInfo "Ejecutando formateo de código con Docker Compose..."
    docker_compose up format
}

# Función para ejecutar ambos, lint y format
function check() {
    printInfo "Ejecutando linter y formateo de código con Docker Compose..."
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
        printError "Comando no encontrado: '$(printCyan -b -- "$1")'"
        printInfo "Ejecutando el script interactivo..."
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
