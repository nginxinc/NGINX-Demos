pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/OnurOzcelikSE/NGINX-Demos.git']]])
                echo 'Repository cloned'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
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
                    def dockerImageTag = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"
                    sh "docker push ${dockerImageTag}"
                    echo 'Docker image pushed'
                }
            }
        }

        stage('Clean Up') {
            steps {
                script {
                    def imageName = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"
                    sh "docker rmi ${imageName}"
                    echo 'Cleanup completed'
                }
            }
        }

        stage('Create and Run Pipeline') {
            steps {
                script {
                    // Load and execute the Jenkinsfile for the new pipeline
                    load 'docker-dive-pipeline/Jenkinsfile'
                }
            }
        }

        stage('Trigger Next Pipeline') {
            steps {
                def buildNumberString = env.BUILD_NUMBER.toString()
                build job: 'docker-dive-pipeline', parameters: [string(name: 'BUILD_NUMBER', value: buildNumberString)]
            }
        }
    }
}


pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
        LOWEST_EFFICIENCY = '0.7'
        HIGHEST_USER_WASTED_PERCENT = '0.2'
        HIGHEST_WASTED_BYTES = '100000000'
    }

    parameters {
        string(name: 'BUILD_NUMBER', description: 'Build number from the previous pipeline')
    }

    stages {
        stage('Pull Docker Image') {
            steps {
                script {
                    def buildNumber = params.BUILD_NUMBER
                    def taggedImage = "${DOCKER_REPOSITORY}:${buildNumber}"
                    sh "docker pull ${taggedImage}"
                }
            }
        }

        stage('Analyze Tagged Docker Image with Dive') {
            steps {
                script {
                    def diveCommand = "dive --ci --lowestEfficiency ${LOWEST_EFFICIENCY} --highestUserWastedPercent ${HIGHEST_USER_WASTED_PERCENT} --highestWastedBytes ${HIGHEST_WASTED_BYTES} ${taggedImage}"

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