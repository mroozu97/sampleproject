pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build (container-based)') {
            steps {
                sh '''
                    set -eux
                    mkdir -p ci-logs

                    echo "==> Building Docker image"
                    docker build -t sampleproject-ci:${BUILD_NUMBER} . \
                        | tee ci-logs/build-${BUILD_NUMBER}.log
                '''
            }
        }

       stage('Test (container based on build)') {
    steps {
        sh '''
            set -eux
            echo "==> Running tests inside container"
            docker run --rm sampleproject-ci:${BUILD_NUMBER} \
              sh -c "pytest" \
              | tee ci-logs/test-${BUILD_NUMBER}.log
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
