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

pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
    }

    parameters {
        string(name: 'BUILD_NUMBER', description: 'Build number from the previous pipeline')
    }

    stages {
        stage('Pull Docker Image') {
            steps {
                script {
                    // Get the BUILD_NUMBER parameter
                    def buildNumber = params.BUILD_NUMBER

                    // Define the tagged image
                    def taggedImage = "${DOCKER_REPOSITORY}:${buildNumber}"

                    // Pull the Docker image
                    sh "docker pull ${taggedImage}"
                }
            }
        }

        stage('Analyze Tagged Docker Image with Dive') {
            steps {
                script {
                    // Define the Dive command with parameters
                    def diveCommand = "dive --ci --lowestEfficiency ${env.LOWEST_EFFICIENCY} --highestUserWastedPercent ${env.HIGHEST_USER_WASTED_PERCENT} --highestWastedBytes ${env.HIGHEST_WASTED_BYTES} ${taggedImage}"

                    // Execute Dive and capture the status
                    def status = sh(script: diveCommand, returnStatus: true)

                    if (status == 0) {
                        echo "Dive analysis completed successfully for ${taggedImage}."
                    } else {
                        error("Dive found inefficiencies in the ${taggedImage} Docker image.")
                    }
                }
            }
        }
    }
}
