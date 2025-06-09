pipeline {
    agent none

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "hamzaxsn/ci-cd"
        IMAGE_TAG = "latest"
        DOCKER_CREDENTIALS_ID = "dockerhub-cred"
        SONARQUBE_ENV = "SonarQube"
    }

    stages {
        stage('SonarQube Analysis') {
            agent { label 'test-agent' }
            environment {
                SONAR_TOKEN = credentials('sonar-cred')
            }
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                        npm install -g sonar-scanner
                        sonar-scanner \
                          -Dsonar.projectKey=ci-cd \
                          -Dsonar.sources=src
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            agent { label 'build-agentt' }
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                    '''
                }
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Security Scan with Trivy') {
            agent { label 'test-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                    '''
                }
                sh "docker pull ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "trivy image ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Push to DockerHub') {
            agent { label 'build-agentt' }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            agent { label 'deploy-agent' }
            steps {
                sh """
                    docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                    docker stop react-app || true
                    docker rm react-app || true
                    docker run -d --name react-app -p 80:80 ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed. No image pushed to DockerHub.'
        }
        success {
            echo '✅ Pipeline completed successfully. Image pushed and deployed.'
        }
        always {
            node('build-agentt') {
                cleanWs()
                sh 'docker system prune -a -f'
            }
        }
    }
}
