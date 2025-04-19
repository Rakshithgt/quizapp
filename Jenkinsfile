pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'  // Make sure this is at least v16.20.1 to match your package requirements
    }

    environment {
        DOCKERHUB_BACKEND_IMAGE = 'rakshithgt96/reactjs-quiz-backend'
        DOCKERHUB_FRONTEND_IMAGE = 'rakshithgt96/reactjs-quiz-frontend'
        SONARQUBE_SERVER = 'http://13.126.141.74:9000'
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "quiz-app"
        RELEASE = "1.0.0"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
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
                            sh 'npm audit fix --force || true'  // Fix vulnerabilities if possible
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'npm install'
                            sh 'npm audit fix --force || true'  // Fix vulnerabilities if possible
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
                            // Add coverage reporting if needed
                            sh 'mkdir -p reports && npm run test -- --coverage --outputFile=reports/coverage.json'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh 'npm test'
                            // Add coverage reporting if needed
                            sh 'mkdir -p reports && npm run test -- --coverage --outputFile=reports/coverage.json'
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
                                  -Dsonar.token=${SONAR_TOKEN} \
                                  -Dsonar.projectName=backend \
                                  -Dsonar.projectVersion=${env.BUILD_NUMBER} \
                                  -Dsonar.javascript.lcov.reportPaths=reports/lcov.info \
                                  -Dsonar.coverage.exclusions=**/test/**,**/node_modules/**
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
                                  -Dsonar.token=${SONAR_TOKEN} \
                                  -Dsonar.projectName=frontend \
                                  -Dsonar.projectVersion=${env.BUILD_NUMBER} \
                                  -Dsonar.javascript.lcov.reportPaths=reports/lcov.info \
                                  -Dsonar.coverage.exclusions=**/test/**,**/node_modules/**
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            parallel {
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
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        dir('reactjs-quiz-app/backend') {
                            sh "docker build --no-cache -t $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG ."
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        dir('reactjs-quiz-app/quiz-app') {
                            sh "docker build --no-cache -t $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG ."
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            parallel {
                stage('Scan Backend Image') {
                    steps {
                        sh "trivy image --exit-code=0 --severity HIGH,CRITICAL $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG || true"
                        // Generate report
                        sh "trivy image --format template --template \"@/usr/local/share/trivy/templates/html.tpl\" -o trivy-backend-report.html $DOCKERHUB_BACKEND_IMAGE:$IMAGE_TAG || true"
                    }
                }
                stage('Scan Frontend Image') {
                    steps {
                        sh "trivy image --exit-code=0 --severity HIGH,CRITICAL $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG || true"
                        // Generate report
                        sh "trivy image --format template --template \"@/usr/local/share/trivy/templates/html.tpl\" -o trivy-frontend-report.html $DOCKERHUB_FRONTEND_IMAGE:$IMAGE_TAG || true"
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
    }

    post {
        always {
            // Archive security reports
            archiveArtifacts artifacts: '**/trivy-*-report.html', allowEmptyArchive: true
            cleanWs()
        }
        success {
            emailext(
                subject: "SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """<p>Pipeline succeeded!</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>View results: <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a></p>
                         <p>Docker Images:</p>
                         <ul>
                           <li>Backend: ${DOCKERHUB_BACKEND_IMAGE}:${IMAGE_TAG}</li>
                           <li>Frontend: ${DOCKERHUB_FRONTEND_IMAGE}:${IMAGE_TAG}</li>
                         </ul>""",
                to: 'rakshithgt222@gmail.com',
                attachmentsPattern: '**/trivy-*-report.html',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """<p>Pipeline failed!</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>View results: <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a></p>""",
                to: 'rakshithgt222@gmail.com',
                attachLog: true,
                mimeType: 'text/html'
            )
        }
    }
}
