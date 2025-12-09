post {
  always {
    script {
      def status = currentBuild.currentResult
      def colorCode = (status == "SUCCESS") ? "#2eb886" :
                      (status == "FAILURE") ? "#ff0000" : "#f0ad4e"
      def emoji = (status == "SUCCESS") ? "✅" :
                  (status == "FAILURE") ? "❌" : "⚠️"

      def msg = """
        *${emoji} Jenkins Build Notification*
        *Job:* ${env.JOB_NAME}
        *Build #:* ${env.BUILD_NUMBER}
        *Status:* ${status}
        *Branch:* ${env.GIT_BRANCH ?: 'N/A'}
        *Commit:* ${env.GIT_COMMIT ?: 'N/A'}
        *Environment:* ${env.ENVIRONMENT ?: 'N/A'}
        *URL:* <${env.BUILD_URL}|Open Jenkins Build>
      """

      slackSend (
        channel: "{{SLACK_CHANNEL}}",
        color: colorCode,
        message: msg,
        teamDomain: "{{SLACK_TEAM_DOMAIN}}",
        tokenCredentialId: "{{SLACK_CREDENTIAL_ID}}"
      )
    }
  }
}
