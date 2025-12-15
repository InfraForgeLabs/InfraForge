// ============================================================
// 🧩 SonarQube Static Code Analysis addon
// Description: Performs SAST scanning using SonarQube
// Compatible with: Declarative Jenkins Pipeline (Groovy)
// ============================================================

stage('SonarQube Analysis') {
    agent any
    environment {
        SCANNER_HOME = tool name: 'SonarQubeScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    }
    steps {
        script {
            echo "🔎 Starting SonarQube Static Analysis for ${APP_NAME}"

            // Ensure environment variables are set
            echo "Using branch: ${BRANCH}, repo: ${REPO_URL}"
            
            withSonarQubeEnv('SonarQubeServer') {
                sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                      -Dsonar.projectKey=${APP_NAME} \
                      -Dsonar.projectName=${APP_NAME} \
                      -Dsonar.projectVersion=${IMAGE_TAG} \
                      -Dsonar.sources=. \
                      -Dsonar.sourceEncoding=UTF-8 \
                      -Dsonar.host.url=${SONAR_HOST_URL:-"http://sonarqube:9000"} \
                      -Dsonar.login=${SONAR_AUTH_TOKEN:-""}
                """
            }
        }
    }
    post {
        always {
            echo "✅ SonarQube scan completed."
        }
        unsuccessful {
            echo "⚠️ SonarQube scan reported issues."
        }
    }
}
