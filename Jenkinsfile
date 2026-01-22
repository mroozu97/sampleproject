pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_DEPS   = "sampleproject-deps:${BUILD_NUMBER}"
    IMAGE_BUILDER= "sampleproject-builder:${BUILD_NUMBER}"
    IMAGE_TESTER = "sampleproject-tester:${BUILD_NUMBER}"
    LOG_DIR      = "ci-logs"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build images (Dependencies -> Builder -> Tester)') {
      steps {
        sh '''
          set -euxo pipefail
          mkdir -p "${LOG_DIR}"

          echo "==> Build Dependencies image: ${IMAGE_DEPS}"
          docker build --pull --no-cache \
            --target dependencies \
            -t "${IMAGE_DEPS}" \
            -f ci/Dockerfile.ci . | tee "${LOG_DIR}/01-deps-build-${BUILD_NUMBER}.log"

          echo "==> Build Builder image (FROM Dependencies): ${IMAGE_BUILDER}"
          docker build --no-cache \
            --target builder \
            -t "${IMAGE_BUILDER}" \
            -f ci/Dockerfile.ci . | tee "${LOG_DIR}/02-builder-build-${BUILD_NUMBER}.log"

          echo "==> Build Tester image (FROM Builder): ${IMAGE_TESTER}"
          docker build --no-cache \
            --target tester \
            -t "${IMAGE_TESTER}" \
            -f ci/Dockerfile.ci . | tee "${LOG_DIR}/03-tester-build-${BUILD_NUMBER}.log"
        '''
      }
    }

    stage('Test (inside Tester container)') {
      steps {
        sh '''
          set -euxo pipefail

          echo "==> Running pytest inside ${IMAGE_TESTER}"
          # -T: bez pseudo-TTY, żeby log był czysty
          docker run --rm "${IMAGE_TESTER}" python -m pytest -vv \
            | tee "${LOG_DIR}/04-pytest-${BUILD_NUMBER}.log"
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'ci-logs/*.log', fingerprint: true
      sh '''
        set +e
        docker rmi -f "${IMAGE_TESTER}" "${IMAGE_BUILDER}" "${IMAGE_DEPS}"
        docker system prune -af
      '''
    }
  }
}
