#!/bin/bash

# Script para ver logs de CloudWatch
# Uso: ./view-logs.sh [backend|lambda-generator|lambda-rebuild]

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para obtener outputs de Terraform
get_terraform_output() {
    cd terraform
    terraform output -raw "$1" 2>/dev/null || echo ""
    cd ..
}

# Función para mostrar uso
show_usage() {
    echo -e "${BLUE}Uso:${NC} $0 [opción]"
    echo ""
    echo "Opciones:"
    echo "  backend           - Ver logs del backend API"
    echo "  lambda-generator  - Ver logs del Lambda Generator"
    echo "  lambda-rebuild    - Ver logs del Lambda Rebuild"
    echo "  list              - Listar todos los log groups disponibles"
    echo ""
    echo "Ejemplos:"
    echo "  $0 backend"
    echo "  $0 lambda-generator"
    echo "  $0 list"
}

# Función para ver logs del backend
view_backend_logs() {
    echo -e "${GREEN}📊 Logs del Backend API${NC}"
    echo ""
    
    # Obtener el nombre del log group
    LOG_GROUP=$(get_terraform_output "backend_log_group_name")
    
    if [ -z "$LOG_GROUP" ]; then
        echo -e "${RED}❌ No se pudo obtener el nombre del log group${NC}"
        echo "¿Has ejecutado 'terraform apply'?"
        exit 1
    fi
    
    # El output es un array JSON, extraer el primer elemento
    LOG_GROUP=$(echo "$LOG_GROUP" | jq -r '.[0]' 2>/dev/null || echo "$LOG_GROUP")
    
    echo -e "${BLUE}Log Group:${NC} $LOG_GROUP"
    echo ""
    
    # Preguntar qué stream ver
    echo "Streams disponibles:"
    echo "1. Application logs (logs de Node.js)"
    echo "2. Syslog (logs del sistema)"
    echo "3. Todos"
    echo ""
    read -p "Selecciona una opción (1-3): " option
    
    case $option in
        1)
            echo -e "\n${GREEN}Mostrando logs de aplicación...${NC}\n"
            aws logs tail "$LOG_GROUP" --filter-pattern "application" --follow
            ;;
        2)
            echo -e "\n${GREEN}Mostrando logs del sistema...${NC}\n"
            aws logs tail "$LOG_GROUP" --filter-pattern "syslog" --follow
            ;;
        3)
            echo -e "\n${GREEN}Mostrando todos los logs...${NC}\n"
            aws logs tail "$LOG_GROUP" --follow
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
}

# Función para ver logs del Lambda Generator
view_lambda_generator_logs() {
    echo -e "${GREEN}📊 Logs del Lambda Generator${NC}"
    echo ""
    
    LOG_GROUP=$(get_terraform_output "lambda_generator_log_group_name")
    
    if [ -z "$LOG_GROUP" ]; then
        echo -e "${RED}❌ No se pudo obtener el nombre del log group${NC}"
        echo "¿Has ejecutado 'terraform apply'?"
        exit 1
    fi
    
    echo -e "${BLUE}Log Group:${NC} $LOG_GROUP"
    echo ""
    echo -e "${GREEN}Mostrando logs en tiempo real...${NC}"
    echo "Presiona Ctrl+C para salir"
    echo ""
    
    aws logs tail "$LOG_GROUP" --follow
}

# Función para ver logs del Lambda Rebuild
view_lambda_rebuild_logs() {
    echo -e "${GREEN}📊 Logs del Lambda Rebuild${NC}"
    echo ""
    
    LOG_GROUP=$(get_terraform_output "lambda_rebuild_log_group_name")
    
    if [ -z "$LOG_GROUP" ]; then
        echo -e "${RED}❌ No se pudo obtener el nombre del log group${NC}"
        echo "¿Has ejecutado 'terraform apply'?"
        exit 1
    fi
    
    echo -e "${BLUE}Log Group:${NC} $LOG_GROUP"
    echo ""
    echo -e "${GREEN}Mostrando logs en tiempo real...${NC}"
    echo "Presiona Ctrl+C para salir"
    echo ""
    
    aws logs tail "$LOG_GROUP" --follow
}

# Función para listar todos los log groups
list_log_groups() {
    echo -e "${GREEN}📋 Log Groups Disponibles${NC}"
    echo ""
    
    echo -e "${BLUE}1. Backend API:${NC}"
    BACKEND_LOG=$(get_terraform_output "backend_log_group_name")
    if [ -n "$BACKEND_LOG" ]; then
        BACKEND_LOG=$(echo "$BACKEND_LOG" | jq -r '.[0]' 2>/dev/null || echo "$BACKEND_LOG")
        echo "   $BACKEND_LOG"
    else
        echo "   (No disponible)"
    fi
    
    echo ""
    echo -e "${BLUE}2. Lambda Generator:${NC}"
    LAMBDA_GEN_LOG=$(get_terraform_output "lambda_generator_log_group_name")
    if [ -n "$LAMBDA_GEN_LOG" ]; then
        echo "   $LAMBDA_GEN_LOG"
    else
        echo "   (No disponible)"
    fi
    
    echo ""
    echo -e "${BLUE}3. Lambda Rebuild:${NC}"
    LAMBDA_REBUILD_LOG=$(get_terraform_output "lambda_rebuild_log_group_name")
    if [ -n "$LAMBDA_REBUILD_LOG" ]; then
        echo "   $LAMBDA_REBUILD_LOG"
    else
        echo "   (No disponible)"
    fi
    
    echo ""
    echo -e "${GREEN}💡 Tip:${NC} Usa './view-logs.sh [backend|lambda-generator|lambda-rebuild]' para ver los logs"
}

# Main
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    backend)
        view_backend_logs
        ;;
    lambda-generator)
        view_lambda_generator_logs
        ;;
    lambda-rebuild)
        view_lambda_rebuild_logs
        ;;
    list)
        list_log_groups
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
