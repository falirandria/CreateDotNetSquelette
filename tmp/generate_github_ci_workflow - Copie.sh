#!/bin/bash

# Demande d'entrée pour le nom du projet et autres informations nécessaires
read -p "Entrez le nom du projet : " PROJECT_NAME
read -p "Entrez le nom de la solution : " SOLUTION_NAME
read -p "Entrez la branche cible pour CI (par exemple, main) : " TARGET_BRANCH

# Créer le répertoire GitHub Actions s'il n'existe pas déjà
mkdir -p .github/workflows

# Créer le fichier GitHub Actions pour CI
cat <<EOL > .github/workflows/ci.yml
name: CI for $PROJECT_NAME

on:
  push:
    branches:
      - $TARGET_BRANCH
  pull_request:
    branches:
      - $TARGET_BRANCH

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.x'

      - name: Restore dependencies
        run: dotnet restore

      - name: Build solution
        run: dotnet build --configuration Release --no-restore

      - name: Run unit tests
        run: dotnet test --no-restore --verbosity normal

      - name: Build Docker images
        run: docker-compose -f docker-compose.yml build

      - name: Run Docker containers
        run: docker-compose -f docker-compose.yml up -d

      - name: Tear down Docker containers
        if: success() || failure()
        run: docker-compose down
EOL

# Instructions supplémentaires
echo "Le workflow GitHub Actions pour le CI a été généré dans .github/workflows/ci.yml"
echo "Assurez-vous que votre fichier docker-compose.yml est correctement configuré pour votre projet."
echo "Vous pouvez ajuster les versions .NET et les commandes supplémentaires dans le fichier ci.yml si nécessaire."