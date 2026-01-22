pipeline {
  agent any

  options {
    timestamps()
  }

  environment {
    IMAGE_NAME = "sampleproject-ci"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build (container-based)') {
      steps {
        sh '''
          set -euxo pipefail
          mkdir -p ci-logs
          echo "==> Building Docker image ${IMAGE_NAME}:${BUILD_NUMBER}"
          docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} . | tee ci-logs/build-${BUILD_NUMBER}.log
        '''
      }
    }

    stage('Test (container based on build)') {
      steps {
        sh '''
          set -euxo pipefail
          echo "==> Running tests inside container ${IMAGE_NAME}:${BUILD_NUMBER}"
          # nie nadpisujemy CMD jeśli nie trzeba — ale i tak wywołamy python -m pytest dla pewności
          docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} python -m pytest | tee ci-logs/test-${BUILD_NUMBER}.log
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'ci-logs/*.log', fingerprint: true
      sh '''
        set +e
        docker rmi -f ${IMAGE_NAME}:${BUILD_NUMBER} || true
        docker system prune -af || true
      '''
    }
  }
}
