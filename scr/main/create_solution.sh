#!/bin/bash

SOLUTION_NAME=$1
SOLUTION_DIR=$2
PROJECT_NAME=$3

# Création de la solution .sln
mkdir -p "$SOLUTION_DIR/$PROJECT_NAME"
cd "$SOLUTION_DIR/$PROJECT_NAME" || exit
mkdir -p "src"
cd "src" || exit

dotnet new sln --name "$SOLUTION_NAME"

echo "Solution created in $SOLUTION_DIR/$PROJECT_NAME with layers added."