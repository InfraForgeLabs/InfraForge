post {
  always {
    script {
      def status = currentBuild.currentResult
      def color = (status == "SUCCESS") ? "#28a745" :
                  (status == "FAILURE") ? "#dc3545" : "#ffc107"

      emailext (
        subject: "📦 Jenkins Pipeline: ${env.JOB_NAME} [#${env.BUILD_NUMBER}] - ${status}",
        body: """
          <html>
          <body style="font-family:Arial,sans-serif;">
            <h2 style="color:${color};">Build Status: ${status}</h2>
            <p><b>Job:</b> ${env.JOB_NAME}</p>
            <p><b>Build #:</b> ${env.BUILD_NUMBER}</p>
            <p><b>Branch:</b> ${env.GIT_BRANCH ?: 'N/A'}</p>
            <p><b>Commit:</b> ${env.GIT_COMMIT ?: 'N/A'}</p>
            <p><b>Environment:</b> ${env.ENVIRONMENT ?: 'N/A'}</p>
            <p><b>URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
          </body>
          </html>
        """,
        mimeType: 'text/html',
        to: "{{DEVOPS_EMAIL}}"
      )
    }
  }
}
