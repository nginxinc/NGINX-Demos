pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/OnurOzcelikSE/NGINX-Demos.git']]])
                echo 'Repository cloned'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def registryCredentials = [
                        usernamePassword(
                            credentialsId: 'DOCKERHUB_CREDENTIALS.id',
                            usernameVariable: 'DOCKERHUB_USERNAME',
                            passwordVariable: 'DOCKERHUB_PASSWORD'
                        )
                    ]
                    echo 'Logged in to DockerHub'

                    docker.withRegistry('https://hub.docker.com', registryCredentials) {
                        def imageName = "onurozcelikse/nginx-hello"
                        def dockerImage = docker.build(imageName)
                        dockerImage.push()
                    echo 'Docker image builded'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'onurozcelikse') 
                echo 'Docker Image Pushed'
                }
            }
        }
        stage('Analyze Docker Image') {
            steps {
                sh 'dive --ci onurozcelikse/nginx-hello --exit-code'
            }
        }
    }
}