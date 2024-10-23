# Demande d'entrée pour chaque paramètre
read -p "Entrez le nom du projet : " PROJECT_NAME
read -p "Entrez le nom de la solution : " SOLUTION_NAME
read -p "Entrez le nom du projet Web API : " WEBAPI_NAME
read -p "Entrez le nom de l'image Docker : " DOCKER_IMAGE_NAME
read -p "Entrez le namespace du projet Web API : " NAMESPACE

# Créer un répertoire pour le projet s'il n'existe pas
if [ ! -d "$PROJECT_NAME" ]; then
  mkdir $PROJECT_NAME
fi

cd $PROJECT_NAME

# Créer la solution .NET et le projet Web API en .NET 8
dotnet new sln -n $SOLUTION_NAME
dotnet new webapi -n $WEBAPI_NAME --framework net8.0
dotnet sln add $WEBAPI_NAME/$WEBAPI_NAME.csproj

# Mettre à jour le namespace dans le projet WebAPI
sed -i "s/namespace WebAPI/namespace $NAMESPACE/" $WEBAPI_NAME/Program.cs
sed -i "s/namespace WebAPI/namespace $NAMESPACE/" $WEBAPI_NAME/Controllers/WeatherForecastController.cs

# Créer le fichier Dockerfile dans le répertoire WebAPI
cat <<EOL > $WEBAPI_NAME/Dockerfile
# Utiliser l'image SDK .NET 8 pour build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /app

# Copier les fichiers et restaurer les dépendances
COPY *.csproj ./
RUN dotnet restore

# Copier tout le reste et builder
COPY . ./
RUN dotnet publish -c Release -o out

# Utiliser l'image runtime .NET 8 pour exécution
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build-env /app/out .

ENTRYPOINT ["dotnet", "$WEBAPI_NAME.dll"]
EOL

# Créer le fichier docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  webapi:
    build:
      context: ./$WEBAPI_NAME
    image: $DOCKER_IMAGE_NAME
    ports:
      - "8080:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
EOL

# Créer un workflow GitHub Actions pour CI
mkdir -p .github/workflows
cat <<EOL > .github/workflows/ci.yml
name: CI for .NET 8 Clean Architecture

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

      - name: Set up .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.x'

      - name: Restore dependencies
        run: dotnet restore ./$WEBAPI_NAME/$WEBAPI_NAME.csproj

      - name: Build solution
        run: dotnet build --configuration Release --no-restore ./$WEBAPI_NAME/$WEBAPI_NAME.csproj

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

# Initialiser git et faire un commit initial
git init
git add .
git commit -m "Initial project setup with .NET 8, Docker, and CI"

# Instructions supplémentaires
echo "Le projet .NET 8 avec Clean Architecture est généré avec Docker et CI."
echo "Pour démarrer le projet, utilisez les commandes suivantes :"
echo "1. cd $PROJECT_NAME"
echo "2. dotnet restore"
echo "3. dotnet build"
echo "4. docker-compose up --build"