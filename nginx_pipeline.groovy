pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
    }

    stages {
        stage('Clone Repository') {
            steps {
                // Checkout the Git repository
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/OnurOzcelikSE/NGINX-Demos.git']]])
                echo 'Repository cloned'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    // Define the Docker image tag
                    def dockerImageTag = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"

                    // Use withCredentials to securely pass Docker Hub credentials
                    withCredentials([usernamePassword(credentialsId: 'DOCKER_HUB_CREDENTIALS', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        echo 'Logged in to DockerHub securely'

                        // Use --password-stdin to securely pass the password to docker login
                        sh """
                        echo \${DOCKER_PASSWORD} | docker login --username \${DOCKER_USERNAME} --password-stdin docker.io
                        docker build -t ${dockerImageTag} ./nginx-hello
                        """
                        echo 'Docker image built'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Define the Docker image tag again
                    def dockerImageTag = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"

                    // Push the Docker image
                    sh "docker push ${dockerImageTag}"
                    echo 'Docker image pushed'
                }
            }
        }

        stage('Clean Up') {
            steps {
                script {
                    // Define the image name for cleanup
                    def imageName = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"

                    // Remove the Docker image
                    sh "docker rmi ${imageName}"
                    echo 'Cleanup completed'
                }
            }
        }

        stage('Trigger Next Pipeline') {
            steps {
                script {
                    def buildNumberString = env.BUILD_NUMBER.toString()
                    build job: 'docker-dive-pipeline', parameters: [string(name: 'BUILD_NUMBER', value: buildNumberString)]
                }
            }
        }
    }
}
