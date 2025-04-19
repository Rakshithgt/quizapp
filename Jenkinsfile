pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        DOCKERHUB_BACKEND_IMAGE = 'rakshithgt96/reactjs-quiz-backend'
        DOCKERHUB_FRONTEND_IMAGE = 'rakshithgt96/reactjs-quiz-frontend'
        SONARQUBE_SERVER = 'http://13.126.141.74:9000'
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "quiz-app"
        RELEASE = "1.0.0"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        BACKEND_SONAR_TOKEN = credentials('sonar-backend-token')
        FRONTEND_SONAR_TOKEN = credentials('sonar-frontend-token')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', 
                    url: 'https://github.com/Rakshithgt/quizapp.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh 'npm install'
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'npm install'
                        }
                    }
                }
            }
        }

        stage('Run Unit Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh 'npm test'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'npm test'
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
    parallel {
        stage('Backend Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-backend-token', variable: 'SONAR_TOKEN')]) {
                    dir('reactjs-quiz-app/backend') {
                        sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=backend \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=${SONARQUBE_SERVER} \
                          -Dsonar.login=${SONAR_TOKEN} \
                          -Dsonar.projectName=backend \
                          -Dsonar.projectVersion=${env.BUILD_NUMBER}
                        """
                    }
                }
            }
        }
        stage('Frontend Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-frontend-token', variable: 'SONAR_TOKEN')]) {
                    dir('reactjs-quiz-app/quiz-app') {
                        sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=frontend \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=${SONARQUBE_SERVER} \
                          -Dsonar.login=${SONAR_TOKEN} \
                          -Dsonar.projectName=frontend \
                          -Dsonar.projectVersion=${env.BUILD_NUMBER}
                        """
                    }
                }
            }
        }
    }
}

        stage('Backend Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-backend-token'
                }
            }
        }

        stage('Frontend Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-frontend-token'
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh "docker build -t $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG ."
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh "docker build -t $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG ."
                        }
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockercred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        # Tag images as latest
                        docker tag $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG $DOCKERHUB_BACKEND_IMAGE:latest
                        docker tag $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG $DOCKERHUB_FRONTEND_IMAGE:latest

                        # Push versioned and latest tags
                        docker push $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG
                        docker push $DOCKERHUB_BACKEND_IMAGE:latest

                        docker push $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG
                        docker push $DOCKERHUB_FRONTEND_IMAGE:latest

                        docker logout
                    """
                }
            }
        }

        stage('Security Scan') {
            parallel {
                stage('Scan Backend Image') {
                    steps {
                        sh "trivy image --exit-code=1 --severity HIGH,CRITICAL $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG"
                    }
                }
                stage('Scan Frontend Image') {
                    steps {
                        sh "trivy image --exit-code=1 --severity HIGH,CRITICAL $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            emailext(
                subject: "CI SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """<p>CI Pipeline Successful!</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <ul>
                           <li>Backend Image: <code>$DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG</code></li>
                           <li>Frontend Image: <code>$DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG</code></li>
                         </ul>""",
                to: 'rakshithgt222@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "CI FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """<p>CI Pipeline Failed!</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>Check the console output for errors.</p>""",
                to: 'rakshithgt222@gmail.com',
                attachLog: true,
                mimeType: 'text/html'
            )
        }
    }
}
