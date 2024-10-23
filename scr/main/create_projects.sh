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
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF.Test" -o "$PROJECT_NAME.$TYPE_OF.Test"
        cd ..
        dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.$TYPE_OF.Test/$PROJECT_NAME.$TYPE_OF.Test.csproj"
    else
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF" -o "$PROJECT_NAME.$TYPE_OF" 
        dotnet sln "$SOLUTION_NAME.sln" add "$PROJECT_NAME.$TYPE_OF/$PROJECT_NAME.$TYPE_OF.csproj"
        mkdir -p "Tests"
        cd "Tests" || exit
        dotnet new "$PROJECT_TYPE" -n "$PROJECT_NAME.$TYPE_OF.Test" -o "$PROJECT_NAME.$TYPE_OF.Test"
        cd ..
        dotnet sln "$SOLUTION_NAME.sln" add "Tests/$PROJECT_NAME.$TYPE_OF.Test/$PROJECT_NAME.$TYPE_OF.Test.csproj"
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

if [[ $SERVICE_CHOICE == "1" ]]; then
    if [[ $ARCHITECTURE_CHOICE == "1" ]]; then
        create_project "classlib" "Services" "Application"
        create_project "console" "Services" "InterfaceAdapters"
        create_project "classlib" "Services" "Application"
        create_project "classlib" "Services" "Domain"
        create_project "classlib" "Services" "Infrastructure"
        add_reference "$PROJECT_NAME.InterfaceAdapters" "$PROJECT_NAME.Application" "Services" ""
        add_reference "$PROJECT_NAME.InterfaceAdapters" "$PROJECT_NAME.Infrastructure" "Services" "Services"
        add_reference "$PROJECT_NAME.Infrastructure" "$PROJECT_NAME.Domain" "Services" "Services"
        add_reference "$PROJECT_NAME.Application" "$PROJECT_NAME.Domain" "" "Services"
        add_reference "$PROJECT_NAME.InterfaceAdapters.Test" "$PROJECT_NAME.InterfaceAdapters" "Tests" "Services"
        add_reference "$PROJECT_NAME.Infrastructure.Test" "$PROJECT_NAME.Infrastructure" "Tests" "Services"
        add_reference "$PROJECT_NAME.Application.Test" "$PROJECT_NAME.Application" "Tests" "Services"
        add_reference "$PROJECT_NAME.Domain.Test" "$PROJECT_NAME.Domain" "Tests" "Services"
    elif [[ $ARCHITECTURE_CHOICE == "2" ]]; then
        create_project "webapi" "" "Presentation"
        create_project "classlib" "" "Domain"
        create_project "classlib" "" "Infrastructure"
        create_project "classlib" "" "Application"
        add_reference "$PROJECT_NAME.Infrastructure" "$PROJECT_NAME.Domain" "" ""
        add_reference "$PROJECT_NAME.Application" "$PROJECT_NAME.Domain" "" ""
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Application" "" ""
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Infrastructure" "" ""
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Application" "" ""
        add_reference "$PROJECT_NAME.Presentation" "$PROJECT_NAME.Infrastructure" "" ""
        add_reference "$PROJECT_NAME.Infrastructure" "$PROJECT_NAME.Domain" "" ""
        add_reference "$PROJECT_NAME.Application" "$PROJECT_NAME.Domain" "" ""
        add_reference "$PROJECT_NAME.Presentation.Test" "$PROJECT_NAME.Presentation" "Tests" ""
        add_reference "$PROJECT_NAME.Infrastructure.Test" "$PROJECT_NAME.Infrastructure" "Tests" ""
        add_reference "$PROJECT_NAME.Application.Test" "$PROJECT_NAME.Application" "Tests" ""
        add_reference "$PROJECT_NAME.Domain.Test" "$PROJECT_NAME.Domain" "Tests" ""
    fi
elif [[ $SERVICE_CHOICE == "2" ]]; then
    create_project "maui" "MobileApp" "Services"
elif [[ $SERVICE_CHOICE == "3" ]]; then
    create_project "wpf" "DesktopApp" "Services"
fi


echo "Projects created successfully."