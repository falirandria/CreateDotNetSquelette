#!/bin/bash

# Paramètres par défaut (peuvent être modifiés dans le script principal)
PROJECT_NAME=""
SOLUTION_NAME=""
DOCKER_IMAGE_NAME=""
SONAR_TOKEN="${SONAR_TOKEN}"

# Emplacement du dossier racine de la solution
SOLUTION_DIR=""

# Types d'architecture disponibles
ARCHITECTURE_CLEAN="Clean Architecture"
ARCHITECTURE_DDD="Domain-Driven Design (DDD)"