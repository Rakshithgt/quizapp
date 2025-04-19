pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'master', description: 'Git branch to build')
        string(name: 'RELEASE', defaultValue: '1.0.0', description: 'App version')
    }

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        DOCKERHUB_USER = 'rakshithgt96'
        DOCKERHUB_BACKEND_IMAGE = "${DOCKERHUB_USER}/reactjs-quiz-backend"
        DOCKERHUB_FRONTEND_IMAGE = "${DOCKERHUB_USER}/reactjs-quiz-frontend"
        SONARQUBE_SERVER = 'http://13.126.141.74:9000'
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "quiz-app"
        IMAGE_TAG = "${params.RELEASE}-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/Rakshithgt/quizapp.git'
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Install Backend Deps') {
                    steps {
                        sh 'cd reactjs-quiz-app/backend && npm ci'
                    }
                }
                stage('Install Frontend Deps') {
                    steps {
                        sh 'cd reactjs-quiz-app/quiz-app && npm ci'
                    }
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Test Backend') {
                    steps {
                        sh 'cd reactjs-quiz-app/backend && npm test || true'
                    }
                }
                stage('Test Frontend') {
                    steps {
                        sh 'cd reactjs-quiz-app/quiz-app && npm test || true'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                    cd reactjs-quiz-app/backend && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=backend
                    cd ../quiz-app && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=frontend
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

        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Docker Image') {
                    steps {
                        sh '''
                        cd reactjs-quiz-app/backend
                        docker build -t $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG .
                        '''
                    }
                }
                stage('Build Frontend Docker Image') {
                    steps {
                        sh '''
                        cd reactjs-quiz-app/quiz-app
                        docker build -t $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG .
                        '''
                    }
                }
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

        stage('Push Docker Images') {
            parallel {
                stage('Push Backend to DockerHub') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG
                            '''
                        }
                    }
                }

                stage('Push Frontend to DockerHub') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG
                            '''
                        }
                    }
                }
            }
        }

        // Optional: Kubernetes deployment
        // stage('Deploy to Kubernetes') {
        //     steps {
        //         sh '''
        //         kubectl apply -f reactjs-quiz-app/kubernetes-manifest/backend.yaml
        //         kubectl apply -f reactjs-quiz-app/kubernetes-manifest/frontend.yaml
        //         '''
        //     }
        // }
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()
        }

        // success {
        //     slackSend channel: '#deployments', message: "✅ Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        // }

        // failure {
        //     slackSend channel: '#deployments', message: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        // }
    }
}
