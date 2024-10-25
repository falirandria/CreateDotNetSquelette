#!/bin/bash

SERVICE_CHOICE=$1
ARCHITECTURE_CHOICE=$2
PROJECT_NAME=$3
SOLUTION_DIR=$4
SOLUTION_NAME=$5

cd $SOLUTION_DIR/$PROJECT_NAME/src

# Fonction to create a specific project
create_project() {
    PROJECT_TYPE=$1
    LAYER=$2
    TYPE_OF=$3
    if [[ -n "$LAYER" ]]; then
        mkdir -p "$LAYER"
        cd "$LAYER" || exit
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF" -o "$PROJECT_NAME.$TYPE_OF"
        cd ..
        dotnet sln "$SOLUTION_NAME.sln" add "$LAYER/$PROJECT_NAME.$TYPE_OF/$PROJECT_NAME.$TYPE_OF.csproj"
        mkdir -p "Tests"
        cd "Tests" || exit
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF.UnitTests" -o "$PROJECT_NAME.$TYPE_OF.UnitTests"
        if [ ! -d "$PROJECT_NAME.IntegrationTests" ]; then
            dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.IntegrationTests" -o "$PROJECT_NAME.IntegrationTests"
            dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.BddTests" -o "$PROJECT_NAME.BddTests"
        fi
        cd ..
        dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.$TYPE_OF.UnitTests/$PROJECT_NAME.$TYPE_OF.UnitTests.csproj"
        if [ ! -d "Tests/$PROJECT_NAME.IntegrationTests" ]; then
            dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj"
            dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.BddTests/$PROJECT_NAME.BddTests.csproj"
        fi
    else
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF" -o "$PROJECT_NAME.$TYPE_OF" 
        dotnet sln "$SOLUTION_NAME.sln" add "$PROJECT_NAME.$TYPE_OF/$PROJECT_NAME.$TYPE_OF.csproj"
        mkdir -p "Tests"
        cd "Tests" || exit
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF.UnitTests" -o "$PROJECT_NAME.$TYPE_OF.UnitTests"
        if [ ! -d "$PROJECT_NAME.IntegrationTests" ]; then
            dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.IntegrationTests" -o "$PROJECT_NAME.IntegrationTests"
            dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.BddTests" -o "$PROJECT_NAME.BddTests"
        fi
        cd ..
        dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.$TYPE_OF.UnitTests/$PROJECT_NAME.$TYPE_OF.UnitTests.csproj"
        if [ ! -d "Tests/$PROJECT_NAME.IntegrationTests" ]; then
            dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.IntegrationTests/$PROJECT_NAME.IntegrationTests.csproj"
            dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.BddTests/$PROJECT_NAME.BddTests.csproj"
        fi
    fi
}

add_reference(){
    PROJECT_CIBLE=$1
    PROJECT_REF=$2
    LAYER_CIBLE=$3
    LAYER_REF=$4
    if [[ -n "$LAYER_CIBLE" ]] && [[ -n "$LAYER_REF" ]]; then
        echo "$LAYER_CIBLE $LAYER_REF"
        dotnet add "./$LAYER_CIBLE/$PROJECT_CIBLE/$PROJECT_CIBLE.csproj" reference "./$LAYER_REF/$PROJECT_REF/$PROJECT_REF.csproj"
    elif [[ -n "$LAYER_CIBLE" ]] && [[ -z "$LAYER_REF" ]]; then
        echo "$LAYER_CIBLE $LAYER_REF"
        dotnet add "./$LAYER_CIBLE/$PROJECT_CIBLE/$PROJECT_CIBLE.csproj" reference "$PROJECT_REF/$PROJECT_REF.csproj"
    elif [[ -z "$LAYER_CIBLE" ]] && [[ -n "$LAYER_REF" ]]; then
        echo "$LAYER_CIBLE $LAYER_REF"
        dotnet add "$PROJECT_CIBLE/$PROJECT_CIBLE.csproj" reference "./$LAYER_REF/$PROJECT_REF/$PROJECT_REF.csproj"
    else
        dotnet add "$PROJECT_CIBLE/$PROJECT_CIBLE.csproj" reference "$PROJECT_REF/$PROJECT_REF.csproj"
    fi
}

create_project_with_reference(){
    Layer=$1   
    TYPE_PROJET=$2      
    if [[ $SERVICE_CHOICE == "1" ]]; then
        create_project "console" "$Layer" "$TYPE_PROJET"
    elif [[ $SERVICE_CHOICE == "2" ]]; then
        create_project "webapi" "$Layer" "$TYPE_PROJET"
    fi
    create_project "classlib" "$Layer" "Application"
    create_project "classlib" "$Layer" "Domain"
    create_project "classlib" "$Layer" "Infrastructure"
    add_reference "$PROJECT_NAME.Infrastructure" "$PROJECT_NAME.Domain" "$Layer" "$Layer"
    add_reference "$PROJECT_NAME.Application" "$PROJECT_NAME.Domain" "$Layer" "$Layer"
    add_reference "$PROJECT_NAME.Application.UnitTests" "$PROJECT_NAME.Application" "Tests" "$Layer"
    add_reference "$PROJECT_NAME.Domain.UnitTests" "$PROJECT_NAME.Domain" "Tests" "$Layer"
    add_reference "$PROJECT_NAME.Infrastructure.UnitTests" "$PROJECT_NAME.Infrastructure" "Tests" "$Layer"
}

if [[ $SERVICE_CHOICE == "1" ]] || [[ $SERVICE_CHOICE == "2" ]]; then
    if [[ $ARCHITECTURE_CHOICE == "1" ]]; then
        create_project_with_reference "Services" "InterfaceAdapters"
        add_reference "$PROJECT_NAME.InterfaceAdapters" "$PROJECT_NAME.Application" "Services" "Services"
        add_reference "$PROJECT_NAME.InterfaceAdapters" "$PROJECT_NAME.Infrastructure" "Services" "Services"
        add_reference "$PROJECT_NAME.InterfaceAdapters.UnitTests" "$PROJECT_NAME.InterfaceAdapters" "Tests" "Services"
        add_reference "$PROJECT_NAME.BddTests" "$PROJECT_NAME.InterfaceAdapters" "Tests" "Services"
        add_reference "$PROJECT_NAME.IntegrationTests" "$PROJECT_NAME.InterfaceAdapters" "Tests" "Services"
    elif [[ $ARCHITECTURE_CHOICE == "2" ]]; then
        create_project_with_reference "" "Presentation"
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Application" "" ""
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Infrastructure" "" ""
        add_reference "$PROJECT_NAME.Presentation.UnitTests" "$PROJECT_NAME.Presentation" "Tests" ""
        add_reference "$PROJECT_NAME.BddTests" "$PROJECT_NAME.Presentation" "Tests" ""
        add_reference "$PROJECT_NAME.IntegrationTests" "$PROJECT_NAME.Presentation" "Tests" ""
    fi

elif [[ $SERVICE_CHOICE == "3" ]] || [[ $SERVICE_CHOICE == "4" ]] ; then
    if [[ $SERVICE_CHOICE == "3" ]]; then
        create_project "maui" "$PROJECT_NAME" ""
    elif [[ $SERVICE_CHOICE == "4" ]]; then
        create_project "wpf" "DesktopApp" ""
    fi
    dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.UnitTests" -o "$PROJECT_NAME.UnitTests"
    dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.IntegrationTests" -o "$PROJECT_NAME.IntegrationTests"
    dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.BddTests" -o "$PROJECT_NAME.BddTests"
    add_reference "$PROJECT_NAME.UnitTests" "$PROJECT_NAME" "Tests" "" ""
    add_reference "$PROJECT_NAME.BddTests" "$PROJECT_NAME" "Tests" "" ""
    add_reference "$PROJECT_NAME.IntegrationTests" "$PROJECT_NAME" "Tests" ""
fi


echo "Projects created successfully."