pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build('onurozcelikse/NGINX-Demos', './nginx-hello')
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'onurozcelikse') {
                        dockerImage.push()
                    }
                }
            }
        }
    }
}
