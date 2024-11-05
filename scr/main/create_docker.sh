#!/bin/bash

DOCKER_IMAGE_NAME=$1
SOLUTION_NAME=$2
SOLUTION_DIR=$3
PROJECT_NAME=$4
SERVICE_CHOICE=$5
ARCHITECTURE_CHOICE=$6

cd $SOLUTION_DIR/$PROJECT_NAME

if [[ $ARCHITECTURE_CHOICE == "1" ]]; then
# Generate file docker-compose.override.yml
cat <<EOL > "docker-compose.override.yml"
services:
  ${PROJECT_NAME}DB:
    container_name: ${PROJECT_NAME}DB
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=${PROJECT_NAME}DB
    restart: always
    ports:
        - "5433:5432"
    volumes:
      - postgres_basket:/var/lib/postgresql/data/

  distributedcache:
    container_name: distributedcache
    restart: always
    ports:
      - "6379:6379"  

  $PROJECT_NAME.InterfaceAdapters:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_HTTP_PORTS=8080
    depends_on:
      - ${PROJECT_NAME}DB
      - distributedcache
    ports:
      - "6001:8080"
  
EOL
cat <<EOL > "docker-compose.yml"
version: '3.4'

services:
  ${PROJECT_NAME}DB:
    image: postgres

  distributedcache:
    image: redis

  $PROJECT_NAME.Api:
    image: ${DOCKER_REGISTRY-}$PROJECT_NAME.InterfaceAdapters
    build:
      context: .
      dockerfile: src/Services/$PROJECT_NAME.InterfaceAdapters/Dockerfile
EOL

elif [[ $ARCHITECTURE_CHOICE == "2" ]]; then
  # Generate file docker-compose.override.yml
cat <<EOL > "docker-compose.override.yml"
version: '3.4'

services:
  ${PROJECT_NAME}DB:
    container_name: ${PROJECT_NAME}DB
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=${PROJECT_NAME}DB
    restart: always
    ports:
        - "5433:5432"
    volumes:
      - postgres_basket:/var/lib/postgresql/data/

  distributedcache:
    container_name: distributedcache
    restart: always
    ports:
      - "6379:6379"  

  $PROJECT_NAME.Presentation:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_HTTP_PORTS=8080
    depends_on:
      - ${PROJECT_NAME}DB
      - distributedcache
    ports:
      - "6001:8080"
      - "6061:8081"
EOL

cat <<EOL > "docker-compose.yml"
version: '3.4'

services:
  ${PROJECT_NAME}DB:
    image: postgres

  distributedcache:
    image: redis

  $PROJECT_NAME.Presentation:
    image: ${DOCKER_REGISTRY-}$PROJECT_NAME.Presentation
    build:
      context: .
      dockerfile: src/$PROJECT_NAME.Presentation/Dockerfile

EOL

fi

# Créer le fichier docker-compose.dcproj pour inclure les projets
cat <<EOL > "docker-compose.dcproj"
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


# Créer un Dockerfile pour chaque projet
create_dockerfile() {
    PROJECT_PATH=$1
    cat <<EOL > "$PROJECT_PATH/Dockerfile"
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["$PROJECT_PATH/$PROJECT_PATH.csproj", "$PROJECT_PATH/"]
RUN dotnet restore "$PROJECT_PATH/$PROJECT_PATH.csproj"
COPY . .
WORKDIR "/src/$PROJECT_PATH"
RUN dotnet build "$PROJECT_PATH.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "$PROJECT_PATH.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$PROJECT_PATH.dll"]
EOL
}

cd src

if [[ $ARCHITECTURE_CHOICE == "1" ]]; then
  # Generate Dockerfiles
  create_dockerfile "Services/$PROJECT_NAME.InterfaceAdapters"
elif [[ $ARCHITECTURE_CHOICE == "2" ]]; then
  create_dockerfile "$PROJECT_NAME.Presentation"
fi

echo "Docker configuration files created."