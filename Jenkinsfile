pipeline {
    agent any

    options {
        timestamps()
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
                  -v "$PWD:/workspace" \
                  -v "$PWD/ci-logs:/logs" \
                  -w /workspace \
                  python:3.12-slim \
                  bash -c "
                    cd sampleproject || true
                    python -m venv venv
                    . venv/bin/activate
                    pip install -U pip setuptools wheel
                    pip install .
                    python -m build
                  " | tee ci-logs/build-${BUILD_NUMBER}.log
                '''
            }
        }

        stage('Test (inside same runtime)') {
            steps {
                sh '''
                set -eux

                docker run --rm \
                  -v "$PWD:/workspace" \
                  -v "$PWD/ci-logs:/logs" \
                  -w /workspace \
                  python:3.12-slim \
                  bash -c "
                    cd sampleproject || true
                    . venv/bin/activate
                    pip install .[test]
                    pytest
                  " | tee ci-logs/test-${BUILD_NUMBER}.log
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
