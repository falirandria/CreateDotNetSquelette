#!/bin/bash

PROJECT_NAME=$1
SOLUTION_NAME=$2
SOLUTION_DIR=$3
SONAR_TOKEN=$4

cd $SOLUTION_DIR/$PROJECT_NAME
# GitHub Actions folder
mkdir -p .github/workflows

# Generate pipeline file GitHub Actions
PIPELINE_FILE=".github/workflows/ci-cd-pipeline.yml"

cat <<EOL > $PIPELINE_FILE
name: .NET Core CI

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
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Setup .NET Core
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    - name: Install SonarScanner
      run: dotnet tool install --global dotnet-sonarscanner
    
    - name: Install dependencies
      run: dotnet restore

    - name: Build solution
      run: dotnet build -p:EnableNETAnalyzers=true -p:AnalysisMode=AllEnabledByDefault --no-restore --configuration Release

    - name: Run tests
      run: |
        dotnet tool install --global coverlet.console
        dotnet test $SOLUTION_NAME.sln --no-build --verbosity detailed /p:CollectCoverage=true /p:CoverletOutputFormat=opencover /p:CoverletOutput=./TestResults/coverage.xml
        
    - name: Run BDD Tests
      run: dotnet test --no-build --configuration Release --filter "Category=BDD" --logger:trx --results-directory ./TestResults
    
    - name: List TestResults
      run: |
        echo "Listing TestResults Directory:"
        ls -R ./TestResults

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        token: \${{ secrets.CODECOV_TOKEN }} 
        fail_ci_if_error: true

    - name: Run SonarQube Scan
      env:
          SONAR_TOKEN: \${{ secrets.SONAR_TOKEN }}
      run: |
        dotnet sonarscanner begin /k:"$PROJECT_NAME" /d:sonar.login="\${{ secrets.SONAR_TOKEN }}" /d:sonar.host.url="http://localhost:9000"
        dotnet build $SOLUTION_NAME.sln
        dotnet sonarscanner end /d:sonar.login="\${{ secrets.SONAR_TOKEN }}"
EOL

echo "GitHub Actions CI pipeline created."