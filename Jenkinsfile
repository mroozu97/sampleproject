pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_DEPS    = "sampleproject-deps:${BUILD_NUMBER}"
    IMAGE_BUILDER = "sampleproject-builder:${BUILD_NUMBER}"
    IMAGE_TESTER  = "sampleproject-tester:${BUILD_NUMBER}"
    IMAGE_DEPLOY  = "sampleproject-deploy:${BUILD_NUMBER}"

    LOG_DIR       = "ci-logs"
    ARTIFACT_DIR  = "ci-artifacts"

    // Jeśli chcesz publikować do zewn. registry:
    // REGISTRY      = "docker.io"
    // DOCKER_REPO   = "mroozu97/sampleproject"   // zmień na swoje
    // PUBLISH_IMAGE = "true"                     // ustaw na true gdy masz creds w Jenkins
    PUBLISH_IMAGE = "false"
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

    stage('Deploy (build runtime image + smoke test)') {
      steps {
        sh '''
          set -euxo pipefail

          echo "==> Build Deploy image (runtime): ${IMAGE_DEPLOY}"
          docker build --no-cache \
            --target deploy \
            -t "${IMAGE_DEPLOY}" \
            -f ci/Dockerfile.ci . | tee "${LOG_DIR}/05-deploy-build-${BUILD_NUMBER}.log"

          echo "==> Smoke test: run ${IMAGE_DEPLOY}"
          docker run --rm "${IMAGE_DEPLOY}" \
            | tee "${LOG_DIR}/06-smoke-${BUILD_NUMBER}.log"
        '''
      }
    }

    stage('Publish (artifact + optional image push)') {
      steps {
        sh '''
          set -euxo pipefail
          mkdir -p "${ARTIFACT_DIR}"

          echo "==> Export wheel artifacts from Builder image (${IMAGE_BUILDER})"
          # Wyciągamy /app/dist z obrazu builder do workspace jako artefakt builda
          CID="$(docker create "${IMAGE_BUILDER}")"
          docker cp "${CID}:/app/dist" "${ARTIFACT_DIR}/dist"
          docker rm -f "${CID}"

          ls -lah "${ARTIFACT_DIR}/dist" | tee "${LOG_DIR}/07-artifacts-list-${BUILD_NUMBER}.log"

          echo "==> Optional: push deploy image to registry? PUBLISH_IMAGE=${PUBLISH_IMAGE}"
        '''
        // Opcjonalny push do registry (włączasz env PUBLISH_IMAGE=true i dodajesz creds)
        script {
          if (env.PUBLISH_IMAGE == 'true') {
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
              sh '''
                set -euxo pipefail

                IMAGE_TAG="${DOCKER_REPO}:${BUILD_NUMBER}"
                LATEST_TAG="${DOCKER_REPO}:latest"

                echo "==> Tagging ${IMAGE_DEPLOY} -> ${IMAGE_TAG} and ${LATEST_TAG}"
                docker tag "${IMAGE_DEPLOY}" "${IMAGE_TAG}"
                docker tag "${IMAGE_DEPLOY}" "${LATEST_TAG}"

                echo "==> Login & push"
                echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

                docker push "${IMAGE_TAG}" | tee "${LOG_DIR}/08-push-${BUILD_NUMBER}.log"
                docker push "${LATEST_TAG}" | tee -a "${LOG_DIR}/08-push-${BUILD_NUMBER}.log"

                docker logout || true
              '''
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'ci-logs/*.log, ci-artifacts/**', fingerprint: true
      sh '''
        set +e
        docker rmi -f "${IMAGE_DEPLOY}" "${IMAGE_TESTER}" "${IMAGE_BUILDER}" "${IMAGE_DEPS}" 2>/dev/null || true
        docker system prune -af
      '''
    }
  }
}
