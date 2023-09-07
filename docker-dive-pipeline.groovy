pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
    }
    properties([
     parameters([
       booleanParam(
         defaultValue: false,
         description: 'isFoo should be false',
         name: 'isFoo'
       ),
       booleanParam(
         defaultValue: true,
         description: 'isBar should be true',
         name: 'isBar'
       ),
     ])
   ])

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
