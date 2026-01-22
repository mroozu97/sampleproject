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

        stage('Build image (container)') {
            steps {
                sh '''
                set -eux
                mkdir -p ci-logs

                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} . \
                  | tee ci-logs/build-${BUILD_NUMBER}.log
                '''
            }
        }

        stage('Test (container based on build)') {
            steps {
                sh '''
                set -eux

                docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} \
                  pytest | tee ci-logs/test-${BUILD_NUMBER}.log
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
