pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'rakshithgt96'
        DOCKERHUB_BACKEND_IMAGE = 'rakshithgt96/reactjs-quiz-backend'
        DOCKERHUB_FRONTEND_IMAGE = 'rakshithgt96/reactjs-quiz-frontend'
        SONARQUBE_SERVER = 'http://52.66.195.119:9000'
        SONARQUBE_TOKEN = 'sqp_0eec8fe2acf9e77936e19c81504342c894e459f8'
        K8S_MANIFEST_PATH = 'kubernetes-manifest'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Rakshithgt/quizapp.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    cd backend && npm install && sonar-scanner -Dsonar.projectKey=backend
                    cd ../quiz-app && npm install && sonar-scanner -Dsonar.projectKey=frontend
                    '''
                }
                
                // Run SonarQube analysis for the entire project
                sh '''
                sonar-scanner \
                  -Dsonar.projectKey=qyiz-app-CI \
                  -Dsonar.sources=. \
                  -Dsonar.host.url=$SONARQUBE_SERVER \
                  -Dsonar.login=$SONARQUBE_TOKEN
                '''
            }
        }

        stage('Build Backend Docker Image') {
            steps {
                sh '''
                cd backend
                docker build -t $DOCKERHUB_BACKEND_IMAGE:latest .
                '''
            }
        }

        stage('Build Frontend Docker Image') {
            steps {
                sh '''
                cd quiz-app
                docker build -t $DOCKERHUB_FRONTEND_IMAGE:latest .
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                trivy image $DOCKERHUB_BACKEND_IMAGE:latest
                trivy image $DOCKERHUB_FRONTEND_IMAGE:latest
                '''
            }
        }

        stage('Push Backend to DockerHub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-credentials') {
                    sh 'docker push $DOCKERHUB_BACKEND_IMAGE:latest'
                }
            }
        }

        stage('Push Frontend to DockerHub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-credentials') {
                    sh 'docker push $DOCKERHUB_FRONTEND_IMAGE:latest'
                }
            }
        }
    }
}
