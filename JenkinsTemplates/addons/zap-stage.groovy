stage('OWASP ZAP DAST Scan') {
  environment {
    TARGET_URL      = "{{TARGET_URL}}"
    ZAP_REPORT_PATH = "{{ZAP_REPORT_PATH}}"
    ZAP_MODE        = "{{ZAP_MODE}}"           // baseline or fullscan
    ZAP_SEVERITY    = "{{ZAP_SEVERITY}}"       // e.g. HIGH,MEDIUM,LOW
  }

  steps {
    script {
      echo "🕵️ Starting OWASP ZAP scan"
      echo "   Target: ${TARGET_URL}"
      echo "   Mode: ${ZAP_MODE}"
      echo "   Severity filter: ${ZAP_SEVERITY}"
      echo "   Output: ${ZAP_REPORT_PATH}"

      sh """
        mkdir -p \$(dirname ${ZAP_REPORT_PATH})

        # Run OWASP ZAP Docker scan
        docker run --rm -v \$(pwd):/zap/wrk \
          -t owasp/zap2docker-stable:${ZAP_MODE} \
          zap-baseline.py \
            -t ${TARGET_URL} \
            -J ${ZAP_REPORT_PATH} \
            -l ${ZAP_SEVERITY} \
            -m 5 \
            -r zap-report.html || true
      """

      echo "📄 ZAP report generated at ${ZAP_REPORT_PATH}"
    }
  }

  post {
    always {
      echo "📦 Archiving ZAP report..."
      archiveArtifacts artifacts: "${ZAP_REPORT_PATH}", onlyIfSuccessful: false
      archiveArtifacts artifacts: "zap-report.html", onlyIfSuccessful: false
    }
    failure {
      echo "❌ ZAP scan encountered issues."
    }
    success {
      echo "✅ OWASP ZAP DAST scan completed successfully."
    }
  }
}
