#!/bin/bash

# Demande les paramètres de configuration pour la solution et les projets
read -p "Entrez le répertoire où créer la solution : " SOLUTION_DIR
read -p "Entrez le nom de la solution : " SOLUTION_NAME
read -p "Entrez le nom du projet API Gateway : " API_GATEWAY_NAME
read -p "Entrez le nom du projet Application Layer : " APPLICATION_LAYER_NAME
read -p "Entrez le nom du projet Domain Layer : " DOMAIN_LAYER_NAME
read -p "Entrez le nom du projet Infrastructure Layer : " INFRASTRUCTURE_LAYER_NAME
read -p "Entrez le nom de l'image Docker : " DOCKER_IMAGE_NAME
read -p "Entrez le namespace du projet : " NAMESPACE

# Demander le type d'architecture (Clean Architecture ou DDD)
echo "Quel type d'architecture voulez-vous utiliser pour votre projet ?"
echo "1) Clean Architecture"
echo "2) Domain-Driven Design (DDD)"
read -p "Choisissez une option (1, 2) : " ARCHITECTURE_TYPE

# Demander le type d'application dans la couche Services (Web API, MAUI, Desktop)
echo "Quel type d'application voulez-vous créer dans la couche Services ?"
echo "1) Web API"
echo "2) Application mobile MAUI"
echo "3) Application Desktop"
read -p "Choisissez une option (1, 2, 3) : " APP_TYPE

case $APP_TYPE in
  1)
    SERVICE_PROJECT_NAME="$API_GATEWAY_NAME"
    PROJECT_TYPE="webapi"
    ;;
  2)
    SERVICE_PROJECT_NAME="MauiApp"
    PROJECT_TYPE="maui"
    ;;
  3)
    SERVICE_PROJECT_NAME="DesktopApp"
    PROJECT_TYPE="wpf"
    ;;
  *)
    echo "Option invalide, création d'une Web API par défaut."
    SERVICE_PROJECT_NAME="$API_GATEWAY_NAME"
    PROJECT_TYPE="webapi"
    ;;
esac

# Créer le répertoire de solution
mkdir -p "$SOLUTION_DIR/$SOLUTION_NAME"
cd "$SOLUTION_DIR/$SOLUTION_NAME"

# Créer la solution
dotnet new sln --name "$SOLUTION_NAME"

# Créer les dossiers selon le type d'architecture
if [ "$ARCHITECTURE_TYPE" == "1" ]; then
  # Clean Architecture
  mkdir -p ApiGateway Application Domain Infrastructure Services
  ARCHITECTURE_NAME="Clean Architecture"
else
  # Domain-Driven Design (DDD)
  mkdir -p ApiGateway Domain Infrastructure Services
  ARCHITECTURE_NAME="Domain-Driven Design (DDD)"
fi

# Créer le projet de la couche Services selon le type sélectionné
dotnet new $PROJECT_TYPE -n "$SERVICE_PROJECT_NAME" -o Services/"$SERVICE_PROJECT_NAME"
dotnet sln add Services/"$SERVICE_PROJECT_NAME"/"$SERVICE_PROJECT_NAME".csproj

# Créer les projets selon l'architecture
if [ "$ARCHITECTURE_TYPE" == "1" ]; then
  # Clean Architecture : Application Layer
  dotnet new classlib -n "$APPLICATION_LAYER_NAME" -o Application/"$APPLICATION_LAYER_NAME"
  dotnet sln add Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj
fi

# Domain Layer
dotnet new classlib -n "$DOMAIN_LAYER_NAME" -o Domain/"$DOMAIN_LAYER_NAME"
dotnet sln add Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj

# Infrastructure Layer
dotnet new classlib -n "$INFRASTRUCTURE_LAYER_NAME" -o Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"
dotnet sln add Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"/"$INFRASTRUCTURE_LAYER_NAME".csproj

# Ajouter des références entre les projets en fonction de l'architecture choisie
if [ "$ARCHITECTURE_TYPE" == "1" ]; then
  # Clean Architecture : Ajouter les références
  dotnet add Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"/"$INFRASTRUCTURE_LAYER_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
  dotnet add Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
  dotnet add Services/"$SERVICE_PROJECT_NAME"/"$SERVICE_PROJECT_NAME".csproj reference Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj
else
  # DDD : Ajouter les références
  dotnet add Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"/"$INFRASTRUCTURE_LAYER_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
  dotnet add Services/"$SERVICE_PROJECT_NAME"/"$SERVICE_PROJECT_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
fi

# Créer le fichier docker-compose.dcproj
cat <<EOL > docker-compose.dcproj
<Project Sdk="Microsoft.Docker.Sdk">
  <PropertyGroup>
    <DockerProjectType>Compose</DockerProjectType>
    <ServiceTargetPath>docker-compose.override.yml</ServiceTargetPath>
  </PropertyGroup>
  <ItemGroup>
    <None Include="docker-compose.yml" />
    <None Include="docker-compose.override.yml" />
  </ItemGroup>
</Project>
EOL

# Créer le fichier docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3.4'

services:
  $SERVICE_PROJECT_NAME:
    image: $DOCKER_IMAGE_NAME
    build:
      context: .
      dockerfile: Services/$SERVICE_PROJECT_NAME/Dockerfile
    ports:
      - "5000:80"
EOL

# Créer le fichier docker-compose.override.yml
cat <<EOL > docker-compose.override.yml
version: '3.4'

services:
  $SERVICE_PROJECT_NAME:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    volumes:
      - ./Services/$SERVICE_PROJECT_NAME:/app
    ports:
      - "5001:80"
EOL

# Créer le Dockerfile pour chaque projet
for PROJECT in "Services/$SERVICE_PROJECT_NAME" "Application/$APPLICATION_LAYER_NAME" "Domain/$DOMAIN_LAYER_NAME" "Infrastructure/$INFRASTRUCTURE_LAYER_NAME"
do
  if [ -d $PROJECT ]; then
    cat <<EOL > $PROJECT/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .

RUN dotnet restore
RUN dotnet build -c Release -o /app

FROM build AS publish
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "${PROJECT_NAME}.dll"]
EOL
  fi
done

# Générer le fichier .dockerignore
cat <<EOL > .dockerignore
**/.classpath
**/.dockerignore
**/.env
**/.git
**/.gitignore
**/.project
**/.settings
**/.toolstarget
**/.vs
**/.vscode
**/*.*proj.user
EOL

# Créer un README.md pour le projet
cat <<EOL > README.md
# $SOLUTION_NAME

Ce projet utilise l'architecture $ARCHITECTURE_NAME avec les couches suivantes :
- API Gateway ou Application MAUI/desktop selon votre choix
- Application (si Clean Architecture)
- Domain
- Infrastructure

Le projet utilise Docker pour faciliter le déploiement et l'exécution dans des environnements isolés.
EOL

# Message de succès
echo "La solution $SOLUTION_NAME avec le projet $SERVICE_PROJECT_NAME a été créée avec succès dans le répertoire $SOLUTION_DIR/$SOLUTION_NAME."