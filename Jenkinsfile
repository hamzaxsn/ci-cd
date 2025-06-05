pipeline {
    agent none

    environment {
        IMAGE_NAME = "hamzaxsn/ci-cd"
        IMAGE_TAG = "latest"
        TEMP_TAG = "temp"
        DOCKER_CREDENTIALS_ID = "dockerhub-cred"
        SONARQUBE_ENV = "SonarQube"
        TEST_IMAGE_TAR = "image.tar"
    }

    stages {

        stage('Build Docker Image') {
            agent { label 'build-agent' }
            steps {
                sh "docker build -t $IMAGE_NAME:$TEMP_TAG ."
                sh "docker save $IMAGE_NAME:$TEMP_TAG -o $TEST_IMAGE_TAR"
                archiveArtifacts artifacts: "$TEST_IMAGE_TAR", fingerprint: true
            }
        }

        stage('Load Image and Security Scan') {
            agent { label 'test-agent' }
            steps {
                // Copy the image tar artifact from build-agent to test-agent workspace
                copyArtifacts(projectName: env.JOB_NAME, selector: specific(env.BUILD_NUMBER), filter: "$TEST_IMAGE_TAR")
                sh "docker load -i $TEST_IMAGE_TAR"
                sh "trivy image $IMAGE_NAME:$TEMP_TAG"
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
                        sonar-scanner -Dsonar.projectKey=ci-cd -Dsonar.sources=src
                    '''
                }
            }
        }

        stage('Tag and Push to Docker Hub') {
            agent { label 'test-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker tag $IMAGE_NAME:$TEMP_TAG $IMAGE_NAME:$IMAGE_TAG
                        docker push $IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            agent { label 'deploy-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker pull $IMAGE_NAME:$IMAGE_TAG
                        docker stop react-app || true
                        docker rm react-app || true
                        docker run -d --name react-app -p 80:80 $IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed.'
        }
        success {
            echo '✅ Pipeline completed successfully.'
        }
        always {
            cleanWs()
        }
    }
}
