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
                    def dockerTaggedImage = "${DOCKER_REPOSITORY}:${buildNumber}"

                    // Pull the Docker image
                    sh "docker pull ${dockerTaggedImage}"
                }
            }
        }

        stage('Analyze Tagged Docker Image with Dive') {
            steps {
                script {
                    // Define the Dive command with parameters
                    def diveCommand = "dive --ci --lowestEfficiency ${env.LOWEST_EFFICIENCY} --highestUserWastedPercent ${env.HIGHEST_USER_WASTED_PERCENT} --highestWastedBytes ${env.HIGHEST_WASTED_BYTES} ${DockerTaggedImage}"

                    // Execute Dive and capture the status
                    def status = sh(script: diveCommand, returnStatus: true)

                    if (status == 0) {
                        echo "Dive analysis completed successfully for ${DockerTaggedImage}."
                    } else {
                        error("Dive found inefficiencies in the ${DockerTaggedImage} Docker image.")
                    }
                }
            }
        }
    }
}
