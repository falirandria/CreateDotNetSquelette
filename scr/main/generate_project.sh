#!/bin/bash

# Load configuration file
source ./config.sh


read -p "Enter project name: " PROJECT_NAME
read -p "Enter solution name: " SOLUTION_NAME
read -p "Enter Docker image name: " DOCKER_IMAGE_NAME

# Select Architecture choice
echo "Select architecture type:"
echo "1) Clean Architecture"
echo "2) Domain-Driven Design (DDD)"
read -p "Enter choice: " ARCHITECTURE_CHOICE


echo "Select type of service:"
echo "1) Web API"
echo "2) Mobile Application (MAUI)"
echo "3) Desktop Application"
read -p "Enter service choice: " SERVICE_CHOICE

read -p "Enter directory for solution generation: " SOLUTION_DIR

PROJET_DIR="$(cd "$(dirname "$0")" && pwd)"

# Execute scripts
$PROJET_DIR/create_solution.sh "$SOLUTION_NAME" "$SOLUTION_DIR" "$PROJECT_NAME"
$PROJET_DIR/create_projects.sh "$SERVICE_CHOICE" "$ARCHITECTURE_CHOICE" "$PROJECT_NAME" "$SOLUTION_DIR" "$SOLUTION_NAME"
$PROJET_DIR/create_docker.sh "$DOCKER_IMAGE_NAME" "$SOLUTION_NAME" "$SOLUTION_DIR" "$PROJECT_NAME" "$SERVICE_CHOICE" "$ARCHITECTURE_CHOICE"
$PROJET_DIR/generate_ci.sh "$PROJECT_NAME" "$SOLUTION_NAME" "$SOLUTION_DIR" "$SONAR_TOKEN"
$PROJET_DIR/create_other_files.sh "$SOLUTION_NAME" "$SOLUTION_DIR" "$PROJECT_NAME"

echo "Project generation complete."