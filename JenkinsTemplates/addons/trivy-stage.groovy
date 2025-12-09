// ============================================================
// 🧩 Trivy Security Scan addon
// Description: Scans container images and source code for vulnerabilities
// Compatible: Jenkins Declarative Pipeline
// ============================================================

stage('Trivy Security Scan') {
    agent any
    environment {
        TRIVY_CACHE_DIR = "${WORKSPACE}/.trivy-cache"
    }
    steps {
        script {
            echo "🧩 Starting Trivy Security Scan..."
            
            // Ensure Trivy is installed
            sh '''
                if ! command -v trivy &> /dev/null; then
                    echo "⚙️ Installing Trivy..."
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                fi
            '''

            // --- Container Image Scan ---
            echo "🔍 Scanning container image: ${IMAGE}"
            sh """
                mkdir -p ${TRIVY_CACHE_DIR}
                trivy image --cache-dir ${TRIVY_CACHE_DIR} --exit-code 0 --severity MEDIUM,HIGH,CRITICAL ${IMAGE} > trivy-image-report.txt
                trivy image --cache-dir ${TRIVY_CACHE_DIR} --exit-code 1 --severity CRITICAL ${IMAGE} || true
            """

            // --- File System (Repo) Scan ---
            echo "📦 Scanning source code repository for vulnerabilities..."
            sh """
                trivy fs --exit-code 0 --severity MEDIUM,HIGH,CRITICAL . > trivy-fs-report.txt
                trivy fs --exit-code 1 --severity CRITICAL . || true
            """

            // --- Reporting ---
            echo "🗂️ Trivy Scan Summary:"
            sh "tail -n 20 trivy-image-report.txt || true"
            sh "tail -n 20 trivy-fs-report.txt || true"

            // --- Archive results ---
            archiveArtifacts artifacts: 'trivy-*.txt', fingerprint: true
        }
    }
    post {
        always {
            echo "✅ Trivy Security Scan completed (reports archived)."
        }
        failure {
            echo "❌ Trivy scan detected CRITICAL vulnerabilities!"
        }
    }
}
