#!/bin/bash
SONARQUBE_PROJECT_KEY="my-ddd-project"
SONAR_TOKEN="<your-sonar-token>"

create_sonar_config() {
    echo "Setting up SonarQube..."

    cat <<EOF > sonar-project.properties
# Required metadata
sonar.projectKey=$SONARQUBE_PROJECT_KEY
sonar.organization=your_org

# Encoding of the source files
sonar.sourceEncoding=UTF-8

# Coverage reporting
sonar.cs.opencover.reportsPaths=./coverage.opencover.xml

# Directories to analyze
sonar.sources=.
sonar.tests=Tests
EOF

    echo "SonarQube configuration created successfully!"
}