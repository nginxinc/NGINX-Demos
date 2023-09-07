pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'OnurOzcelikSE/NGINX-Demos'
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
                    withCredentials([(credentialsId: 'DOCKER_REGISTRY_CREDENTIALS', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD)']) {
                        sh "docker login --username ${DOCKER_USERNAME} --password ${DOCKER_PASSWORD} docker.io"
                        echo 'Logged in to DockerHub'

                        sh "docker build -t ${dockerImageTag} ./nginx-hello"
                        echo 'Docker image builded'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    sh "docker push ${dockerImageTag}"
                    echo 'Docker image pushed'
                }
            }
        }

        stage('Clean Up') {
            steps {
                script{
                def imageName = ${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}
                    sh "rm -f ${imageName}"
                    echo 'Cleanup completed'
                }
            }
        }

        stage('Trigger Next Pipeline') {
            steps {
                script {
                    build job: 'docker-image'
                }
            }
        }
    }
}

pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'OnurOzcelikSE/NGINX-Demos'
        LOWEST_EFFICIENCY = '0.7'
        HIGHES_USER_WASTED_PERCENT= '0.2'
        HIGHEST_WASTED_YTS = '100000000'
    }

    parameters {
        string(name: 'BUILD_NUMBER', description: 'Build number from the previous pipeline')
    }

    stages {
        stage ('Pull Docker Image') {
            steps {
                script {
                    def buildNumber = params.BUILD_NUMBER
                    def taggedImage = "${DOCKER_REPOSITORY}:${env.BUILD_NUMBER}"
                    sh "docker pull ${taggedImage}"
                }
            }
        }
    
    stage('Analyze Tagged Docker Image with Dive'){
        steps {
            script {
                def diveCommand = "dive --ci --lowestEfficiency ${LOWEST_EFFICIENCY} --highestUserWastedPercent ${HIGHEST_USER_WASTED_PERCENT} --highestWastedBytes ${HIGHEST_WASTED_BYTES} ${taggedImage}"

                def status = sh(script: diveCommand, returnStatus: true)

                if (status == 0) {
                    echo "Dive analysis completed successfully for ${taggedImage}."
                }
                else {
                    error("Dive found inefficiencies in the ${taggedImage} Docker image.")
                }
                }
            }
        }
    }
}
