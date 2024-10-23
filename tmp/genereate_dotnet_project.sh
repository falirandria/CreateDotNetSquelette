#!/bin/bash
# Choix du type de projet pour la couche Services
echo "Choisissez le type de projet pour la couche Services:"
echo "1) Web API"
echo "2) Application mobile (MAUI)"
echo "3) Application Desktop"
read -p "Entrez le numéro correspondant à votre choix : " PROJECT_TYPE_CHOICE

# Variable pour le type de projet dans la couche Services
PROJECT_TYPE=""

case $PROJECT_TYPE_CHOICE in
    1)
        PROJECT_TYPE="webapi"
        ;;
    2)
        PROJECT_TYPE="maui"
        ;;
    3)
        PROJECT_TYPE="winforms"
        ;;
    *)
        echo "Choix invalide, création d'un projet Web API par défaut."
        PROJECT_TYPE="webapi"
        ;;
esac



# Demande les paramètres de configuration pour la solution et les projets
read -p "Entrez le répertoire où créer la solution : " SOLUTION_DIR
read -p "Entrez le nom de la solution : " SOLUTION_NAME
read -p "Entrez le nom du projet API Gateway : " API_GATEWAY_NAME
read -p "Entrez le nom du projet Application Layer : " APPLICATION_LAYER_NAME
read -p "Entrez le nom du projet du Domain : " DOMAIN_NAME
read -p "Entrez le nom du projet Service layers : " SERVICE_LAYER_NAME
read -p "Entrez le nom du projet Infrastructure : " INFRASTRUCTURE_NAME
read -p "Entrez le nom de l'image Docker : " DOCKER_IMAGE_NAME
read -p "Entrez le namespace du projet : " NAMESPACE

# Créer le répertoire de solution
mkdir -p "$SOLUTION_DIR/$SOLUTION_NAME"
cd "$SOLUTION_DIR/$SOLUTION_NAME"

# Créer la solution
dotnet new sln --name "$SOLUTION_NAME"

# Créer les projets par layers
mkdir -p ApiGateway Application Domain Infrastructure

# Créer le projet API Gateway
dotnet new webapi -n "$API_GATEWAY_NAME" -o ApiGateway/"$API_GATEWAY_NAME"
dotnet sln add ApiGateway/"$API_GATEWAY_NAME"/"$API_GATEWAY_NAME".csproj

# Créer le projet Application Layer
dotnet new classlib -n "$APPLICATION_LAYER_NAME" -o Application/"$APPLICATION_LAYER_NAME"
dotnet sln add Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj

# Créer le projet Services basé sur le choix de l'utilisateur
dotnet new $PROJECT_TYPE -n "$SERVICES_PROJECT_NAME" -o $SERVICE_LAYER_NAME/"$SERVICES_PROJECT_NAME"
dotnet sln add $SERVICE_LAYER_NAME/"$SERVICES_PROJECT_NAME"/"$SERVICES_PROJECT_NAME".csproj


# Créer le projet Domain Layer
dotnet new classlib -n "$SERVICE_LAYER_NAME" -o $SERVICE_LAYER_NAME/"$DOMAIN_NAME"
dotnet sln add $SERVICE_LAYER_NAME/"$DOMAIN_NAME"/"$DOMAIN_NAME".csproj

# Créer le projet Infrastructure Layer
dotnet new classlib -n "$INFRASTRUCTURE_LAYER_NAME" -o $SERVICE_LAYER_NAME/"$INFRASTRUCTURE_NAME"
dotnet sln add Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"/"$INFRASTRUCTURE_LAYER_NAME".csproj

# Ajouter des références entre les projets (par exemple, Infrastructure dépend de Domain)
dotnet add Infrastructure/"$INFRASTRUCTURE_LAYER_NAME"/"$INFRASTRUCTURE_LAYER_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
dotnet add Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj reference Domain/"$DOMAIN_LAYER_NAME"/"$DOMAIN_LAYER_NAME".csproj
dotnet add ApiGateway/"$API_GATEWAY_NAME"/"$API_GATEWAY_NAME".csproj reference Application/"$APPLICATION_LAYER_NAME"/"$APPLICATION_LAYER_NAME".csproj

# Créer le fichier docker-compose.dcproj pour inclure les projets
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
  $API_GATEWAY_NAME:
    image: $DOCKER_IMAGE_NAME
    build:
      context: .
      dockerfile: ApiGateway/$API_GATEWAY_NAME/Dockerfile
    ports:
      - "5000:80"
EOL

# Créer le fichier docker-compose.override.yml pour les environnements spécifiques
cat <<EOL > docker-compose.override.yml
version: '3.4'

services:
  $API_GATEWAY_NAME:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    volumes:
      - ./ApiGateway/$API_GATEWAY_NAME:/app
    ports:
      - "5001:80"
EOL

# Créer le fichier Dockerfile pour chaque projet
for PROJECT in "ApiGateway/$API_GATEWAY_NAME" "Application/$APPLICATION_LAYER_NAME" "Domain/$DOMAIN_LAYER_NAME" "Infrastructure/$INFRASTRUCTURE_LAYER_NAME"
do
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

Ce projet utilise une architecture propre (Clean Architecture) avec les couches suivantes :
- API Gateway
- Application
- Domain
- Infrastructure

Le projet utilise Docker pour faciliter le déploiement et l'exécution dans des environnements isolés.
EOL

# Message de succès
echo "La solution $SOLUTION_NAME a été créée avec succès dans le répertoire $SOLUTION_DIR/$SOLUTION_NAME."