#!/bin/bash

SOLUTION_NAME=$1
SOLUTION_DIR=$2
PROJECT_NAME=$3

cd $SOLUTION_DIR/$PROJECT_NAME

mkdir -p "docs"

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

Client (Browser, Mobile App)
      |
      |---> API Gateway (agrégation, authentification, routing)
                |
                |---> Service REST (Clean Architecture)
                         |
                         |---> Interface Adapters (Contrôleurs REST)
                         |---> Application Layer (Use cases)
                         |---> Domain Layer (Entities, Domain Logic)
                         |---> Infrastructure Layer (Repositories, DDS)


- Application : Use Cases (Application)
- Domain
- Infrastructure: Gestion des interactions avec les systèmes externes
- Interface Adapters : Interface Adapters (Interface)

Le projet utilise Docker pour faciliter le déploiement et l'exécution dans des environnements isolés.
EOL