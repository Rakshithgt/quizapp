pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('dockercred')
        SONAR_TOKEN = credentials('SonarQube-Token')
        SONARQUBE_SERVER = 'http:13.126.141.74:9000'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            failFast false
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh 'npm install'
                            sh 'npm audit fix --force || true' // Continue even if audit fix fails
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'npm install'
                            sh 'npm audit fix --force || true' // Continue even if audit fix fails
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            failFast false
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh 'mkdir -p reports'
                            sh 'npx jest --passWithNoTests --coverage --collectCoverageFrom=**/*.js --coverageReporters=json --coverageDirectory=reports || true'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'mkdir -p reports'
                            sh 'npx jest --passWithNoTests --coverage --collectCoverageFrom=**/*.js --coverageReporters=json --coverageDirectory=reports'
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            failFast false
            parallel {
                stage('Backend Analysis') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            withSonarQubeEnv('SonarQube') {
                                sh 'npx sonar-scanner -Dsonar.projectKey=quiz-app-backend -Dsonar.sources=. -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_TOKEN'
                            }
                        }
                    }
                }
                stage('Frontend Analysis') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            withSonarQubeEnv('SonarQube') {
                                sh 'npx sonar-scanner -Dsonar.projectKey=quiz-app-frontend -Dsonar.sources=. -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_TOKEN'
                            }
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Build Docker Images') {
            failFast false
            parallel {
                stage('Backend Image') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh 'docker build -t quiz-app-backend:${BUILD_NUMBER} .'
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'docker build -t quiz-app-frontend:${BUILD_NUMBER} .'
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            failFast false
            parallel {
                stage('Scan Backend Image') {
                    steps {
                        sh 'docker scan --accept-license --exclude-base --file reactjs-quiz-app/backend/Dockerfile quiz-app-backend:${BUILD_NUMBER} || true'
                    }
                }
                stage('Scan Frontend Image') {
                    steps {
                        sh 'docker scan --accept-license --exclude-base --file reactjs-quiz-app/quiz-app/Dockerfile quiz-app-frontend:${BUILD_NUMBER} || true'
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        docker.image("quiz-app-backend:${BUILD_NUMBER}").push()
                        docker.image("quiz-app-frontend:${BUILD_NUMBER}").push()
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/reports/**/*', allowEmptyArchive: true
            cleanWs()
        }
        success {
            emailext (
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></p>""",
                to: 'rakshithgt222@gmail.com'
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a></p>""",
                to: 'rakshithgt222@gmail.com'
            )
        }
    }
}
