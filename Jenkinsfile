pipeline {
    agent any

    environment {
        // Your Docker Hub username
        DOCKER_USER = "dhanushranga1"
        IMAGE_NAME = "${DOCKER_USER}/myapp"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Start Minikube') {
            steps {
                // Start minikube (if not running) using the docker driver
                // We must run this as the 'jenkins' user
                sh 'minikube status ||minikube start --driver=docker'
                // Point kubectl to minikube's docker env
                sh 'eval $(minikube -p minikube docker-env)'
            }
        }

        stage('Clone Repo') {
            steps {
                // This is your GitHub repo URL
                git 'https://github.com/Dhanushranga1/lab7-blue-green-app.git'
            }
        }

        stage('Apply Initial K8s Config') {
            steps {
                // Apply all YAMLs. This creates/updates the deployments and service.
                sh 'kubectl apply -f k8s/'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build the new image
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                // Tag this new build as 'latest' as well
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                // Use the credential ID 'dockerhub-creds' we created
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER_VAR', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER_VAR --password-stdin"
                    // Push the specific build tag
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    // Push the 'latest' tag
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Determine Target (Inactive) Environment') {
            steps {
                script {
                    // Check which color is currently active in the service
                    def activeColor = sh(script: 'kubectl get service myapp-service -o jsonpath="{.spec.selector.color}"', returnStdout: true).trim()

                    if (activeColor == 'blue') {
                        env.NEW_COLOR = 'green'
                    } else {
                        env.NEW_COLOR = 'blue'
                    }
                    echo "Active color is ${activeColor}. Deploying to inactive color: ${env.NEW_COLOR}."
                }
            }
        }

        stage('Deploy to Kubernetes (Inactive)') {
            steps {
                // Update the *inactive* deployment with the new image
                sh "kubectl set image deployment/myapp-${env.NEW_COLOR} myapp=${IMAGE_NAME}:${IMAGE_TAG} --record"
                // Wait for the new deployment to be ready
                sh "kubectl rollout status deployment/myapp-${env.NEW_COLOR}"
            }
        }

        stage('Manual Approval to Switch Traffic') {
            steps {
                // This is the manual gate for Blue-Green
                timeout(time: 5, unit: 'MINUTES') {
                    input "Switch production traffic to ${env.NEW_COLOR} version?"
                }
            }
        }

        stage('Switch Service (Promote to Production)') {
            steps {
                // Patch the service to point its selector to the new color
                sh "kubectl patch service myapp-service -p '{\"spec\": {\"selector\": {\"app\": \"myapp\", \"color\": \"${env.NEW_COLOR}\"}}}'"
                echo "Traffic switched to ${env.NEW_COLOR}"
            }
        }
    }
}
