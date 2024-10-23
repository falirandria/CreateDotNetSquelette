#!/bin/bash

# This script generate a file GitHub Actions for CI/CD.
cd $SOLUTION_DIR/$PROJECT_NAME

read -p "Nom du projet .NET (par défaut: MyDotNetProject): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-MyDotNetProject}

read -p "Nom du fichier Dockerfile (par défaut: Dockerfile): " DOCKERFILE_NAME
DOCKERFILE_NAME=${DOCKERFILE_NAME:-Dockerfile}

read -p "Nom de l'image Docker (par défaut: mydotnetapp): " DOCKER_IMAGE_NAME
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-mydotnetapp}

# GitHub Actions folder
mkdir -p .github/workflows

# Pipeline file GitHub Actions
PIPELINE_FILE=".github/workflows/ci-cd-pipeline.yml"

cat <<EOL > $PIPELINE_FILE
name: .NET CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v2

    - name: Setup .NET
      uses: actions/setup-dotnet@v2
      with:
        dotnet-version: '8.x'  # Utilisation de .NET 8
    
    - name: Restore dependencies
      run: dotnet restore

    - name: Build
      run: dotnet build --no-restore --configuration Release

    - name: Run tests
      run: dotnet test --no-build --verbosity normal --configuration Release

    - name: Publish
      run: dotnet publish --configuration Release --output ./publish

    - name: Build Docker image
      run: docker build -t $DOCKER_IMAGE_NAME -f $DOCKERFILE_NAME .

    - name: Push Docker image to Docker Hub
      env:
        DOCKER_USER: \${{ secrets.DOCKER_USER }}
        DOCKER_PASSWORD: \${{ secrets.DOCKER_PASSWORD }}
      run: |
        echo "\$DOCKER_PASSWORD" | docker login -u "\$DOCKER_USER" --password-stdin
        docker tag $DOCKER_IMAGE_NAME \${{ secrets.DOCKER_USER }}/$DOCKER_IMAGE_NAME:latest
        docker push \${{ secrets.DOCKER_USER }}/$DOCKER_IMAGE_NAME:latest
EOL


echo "The pipeline CI has generated on $PIPELINE_FILE"