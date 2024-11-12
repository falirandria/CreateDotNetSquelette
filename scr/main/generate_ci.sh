#!/bin/bash

PROJECT_NAME=$1
SOLUTION_NAME=$2
SOLUTION_DIR=$3
SONAR_TOKEN=$4

cd $SOLUTION_DIR/$PROJECT_NAME
# GitHub Actions folder
mkdir -p .github/workflows

# Generate pipeline file GitHub Actions
PIPELINE_FILE=".github/workflows/pipeline.yml"

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
      run: dotnet restore src/$SOLUTION_NAME.sln

    - name: Build solution
      run: dotnet build src/$SOLUTION_NAME.sln -p:EnableNETAnalyzers=true -p:AnalysisMode=AllEnabledByDefault --no-restore --configuration Release

    - name: Run tests
      run: |
        dotnet tool install --global coverlet.console
        dotnet test src/$SOLUTION_NAME.sln --no-build --verbosity detailed /p:CollectCoverage=true /p:CoverletOutputFormat=opencover /p:CoverletOutput=./TestResults/coverage.xml
        
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
        dotnet build src/$SOLUTION_NAME.sln
        dotnet sonarscanner end /d:sonar.login="\${{ secrets.SONAR_TOKEN }}"
EOL


# Generate pipeline file GitHub Actions
PIPELINE_FILE_TEST=".github/workflows/run_test.yml"

cat <<EOL > $PIPELINE_FILE_TEST
name: .NET Core CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main"]

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
        
    - name: Install dependencies
      run: dotnet restore src/$SOLUTION_NAME.sln
    
    - name: Clean Build Cache
      run: dotnet clean src/$SOLUTION_NAME.sln -c Debug

    - name: Build solution
      run: dotnet build src/$SOLUTION_NAME.sln -p:EnableNETAnalyzers=true -p:AnalysisMode=AllEnabledByDefault --no-restore --configuration Debug

    - name: Create TestResults Directory
      run: mkdir -p ./TestResults
  
    - name: Run unit tests
      run: |
        dotnet tool install --global coverlet.console
        dotnet test src/$SOLUTION_NAME.sln --filter "Category=Unit"  --no-build --configuration Debug --logger:trx --results-directory ./TestResults


    - name: List TestResults
      run: |
        echo "Listing TestResults Directory:"
        ls -R ./TestResults
      
    - name: Upload coverage report
      uses: actions/upload-artifact@v3
      with:
        name: coverage-report
        path: ./TestResults/*.xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        token: ${{ secrets.CODECOV_TOKEN }} 
        fail_ci_if_error: true       
    
    - name: Start the application
      run: |
        dotnet run --no-build --project src/$PROJECT_NAME.Presentation/$PROJECT_NAME.Presentation.csproj &
        echo $! > app.pid
      shell: bash

    - name: Wait for the application to start
      run: sleep 8 
    
    - name: Run BDD Tests
      run: |
        dotnet test src/$SOLUTION_NAME.sln --no-build --configuration Debug --filter "Category=BDD" --logger:trx --results-directory ./TestResults
    
    - name: Stop the application using the PID
      run: |
        if [ -s app.pid ] && kill -0 $(cat app.pid) 2>/dev/null; then
          kill $(cat app.pid)
          rm -f app.pid
        else
          echo "No valid PID found in app.pid or process is not running."
        fi
      shell: bash

EOL

# Generate Docker pipeline file GitHub Actions
PIPELINE_FILE_DOCKER=".github/workflows/docker.yml"

cat <<EOL > $PIPELINE_FILE_DOCKER
name: .NET Core CI
name: Push Image to Docker Hub
on:
    push:
      branches: [ "main" ]
    pull_request:
      branches: [ "main" ]
jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - name: get code
        uses: actions/checkout@v3
      
      - name: Restore dependencies
        run: dotnet restore

      - name: Build project
        run: dotnet build ./src/$SOLUTION_NAME.sln --configuration Release --no-restore

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: setup docker buildx
        uses: docker/setup-buildx-action@v1
        id: buildx

      - name: build and push docker image
        uses: docker/build-push-action@v2
        with:
          context: ./
          file: ./src/$PROJECT_NAME.Presentation/Dockerfile
          builder: ${{ steps.buildx.outputs.name }}
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/$PROJECT_NAME:v1

      - name: verify
        run: echo ${{ steps.docker_build.outputs.digest}}
  deploy:
    needs: docker
    runs-on: ubuntu-latest
    steps:
      - name: Publish .NET project
        run: dotnet publish ./src/$SOLUTION_NAME.sln -c Release -o output

      - name: Archive artifact to github
        run: |
          zip -r $PROJECT_NAME.zip output/
          mv $PROJECT_NAME.zip ${{ github.workspace }}

      - name: Deploy to Nexus Repository
        uses: actions/upload-artifact@v3
        with:
            name: Docker image
            path: $PROJECT_NAME:latest

EOL

echo "GitHub Actions CI pipeline created."