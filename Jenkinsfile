pipeline {
    agent none

    environment {
        IMAGE_NAME = "hamzaxsn/ci-cd"
        IMAGE_TAG = "latest"
        DOCKER_CREDENTIALS_ID = "dockerhub-cred"
        SONARQUBE_ENV = "SonarQube"
    }

    stages {
        stage('Checkout') {
            agent { label 'build-agentt' }
            steps {
                git 'https://github.com/hamzaxsn/ci-cd.git'
            }
        }

        stage('Install Dependencies & Build App') {
            agent { label 'build-agentt' }
            steps {
                sh '''
                    npm install
                    npm run build
                '''
            }
        }

        stage('Build Docker Image') {
            agent { label 'build-agentt' }
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Security Scan with Trivy') {
            agent { label 'test-agent' }
            steps {
                sh 'trivy image $IMAGE_NAME:$IMAGE_TAG'
            }
        }

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
                          -Dsonar.sources=src \
                    '''
                }
            }
        }

        stage('Push to DockerHub') {
            agent { label 'build-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker push $IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            agent { label 'deploy-agent' }
            steps {
                sh '''
                    docker pull $IMAGE_NAME:$IMAGE_TAG
                    docker stop react-app || true
                    docker rm react-app || true
                    docker run -d --name react-app -p 80:80 $IMAGE_NAME:$IMAGE_TAG
                '''
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
    }
}
