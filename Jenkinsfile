pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'rakshtihgt96/your-app'
        SONARQUBE_SERVER = 'your-sonarqube-server'
        K8S_DEPLOYMENT = 'your-kubernetes-deployment.yaml'
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
                    sh 'npm install'
                    sh 'npm run build'
                    sh 'sonar-scanner -Dsonar.projectKey=your-project-key -Dsonar.sources=src'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:latest .'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh 'trivy image $DOCKER_IMAGE:latest'
            }
        }

        stage('Push to DockerHub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-credentials') {
                    sh 'docker push $DOCKER_IMAGE:latest'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig(credentialsId: 'k8s-config') {
                    sh 'kubectl apply -f $K8S_DEPLOYMENT'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
