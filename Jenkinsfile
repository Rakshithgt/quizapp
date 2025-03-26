pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        DOCKERHUB_USER = 'rakshithgt96'
        DOCKER_PASS = 'dockerhub'
        DOCKERHUB_BACKEND_IMAGE = 'rakshithgt96/reactjs-quiz-backend'
        DOCKERHUB_FRONTEND_IMAGE = 'rakshithgt96/reactjs-quiz-frontend'
        SONARQUBE_SERVER = 'http://52.66.195.119:9000'
        K8S_MANIFEST_PATH = 'kubernetes-manifest'
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "quiz-app"
        RELEASE = "1.0.0"
        IMAGE_NAME = "${DOCKERHUB_USER}/${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/Rakshithgt/quizapp.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                    cd backend && npm install && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=backend
                    cd ../quiz-app && npm install && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=frontend
                    '''
                }

                withCredentials([string(credentialsId: 'SonarQube-Token', variable: 'SONARQUBE_TOKEN')]) {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                      -Dsonar.projectKey=quiz-app-CI \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=$SONARQUBE_SERVER \
                      -Dsonar.login=$SONARQUBE_TOKEN
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('Build Backend Docker Image') {
            steps {
                sh '''
                cd reactjs-quiz-app/backend && \
                docker build -t $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG .
                '''
            }
        }

        stage('Build Frontend Docker Image') {
            steps {
                sh '''
                cd reactjs-quiz-app/backend && \
                docker build -t $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG .
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                trivy image --exit-code=0 --severity HIGH,CRITICAL $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG || true
                trivy image --exit-code=0 --severity HIGH,CRITICAL $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG || true
                '''
            }
        }

        stage('Push Backend to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Push Frontend to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG
                    '''
                }
            }
        }
    }
}
