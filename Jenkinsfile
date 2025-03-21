pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'rakshithgt96'
        DOCKERHUB_BACKEND_IMAGE = 'rakshithgt96/reactjs-quiz-backend'
        DOCKERHUB_FRONTEND_IMAGE = 'rakshithgt96/reactjs-quiz-frontend'
        SONARQUBE_SERVER = 'your-sonarqube-server'
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
                    sh 'cd backend && npm install && sonar-scanner -Dsonar.projectKey=backend'
                    sh 'cd quiz-app && npm install && sonar-scanner -Dsonar.projectKey=frontend'
                }
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
                sh 'trivy image $DOCKERHUB_BACKEND_IMAGE:latest'
                sh 'trivy image $DOCKERHUB_FRONTEND_IMAGE:latest'
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

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig(credentialsId: 'k8s-config') {
                    sh '''
                    kubectl apply -f $K8S_MANIFEST_PATH/database.yaml
                    kubectl apply -f $K8S_MANIFEST_PATH/secret.yaml
                    kubectl apply -f $K8S_MANIFEST_PATH/backend.yaml
                    kubectl apply -f $K8S_MANIFEST_PATH/frontend.yaml
                    kubectl apply -f $K8S_MANIFEST_PATH/ingress.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
