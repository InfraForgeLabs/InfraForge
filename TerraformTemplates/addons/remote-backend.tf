stage('Terraform Init') {
  steps {
    withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
      sh '''
      terraform init \
        -backend-config="bucket=${PROJECT}-tfstate" \
        -backend-config="key=terraform.tfstate" \
        -backend-config="region=us-east-1" \
        -backend-config="dynamodb_table=${PROJECT}-lock" \
        -reconfigure
      '''
    }
  }
}
