pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        IMAGE_NAME = "sampleproject-ci"
        BUILD_ID_SAFE = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build (inside container)') {
            steps {
                sh '''
                set -eux

                mkdir -p ci-logs

                docker run --rm \
                  -v "$PWD:/app" \
                  -v "$PWD/ci-logs:/logs" \
                  -w /app \
                  python:3.12-slim \
                  bash -c "
                    python -m venv venv &&
                    . venv/bin/activate &&
                    pip install -U pip setuptools wheel &&
                    pip install . &&
                    python -m build
                  " | tee ci-logs/build-${BUILD_ID_SAFE}.log
                '''
            }
        }

        stage('Test (same container runtime)') {
            steps {
                sh '''
                set -eux

                docker run --rm \
                  -v "$PWD:/app" \
                  -v "$PWD/ci-logs:/logs" \
                  -w /app \
                  python:3.12-slim \
                  bash -c "
                    . venv/bin/activate &&
                    pip install .[test] &&
                    pytest
                  " | tee ci-logs/test-${BUILD_ID_SAFE}.log
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'ci-logs/*.log', fingerprint: true
            sh 'docker system prune -af || true'
        }
    }
}
