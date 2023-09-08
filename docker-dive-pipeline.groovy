pipeline {
    agent any

    environment {
        DOCKER_REPOSITORY = 'onurozcelikse/nginx-demos'
        LOWEST_EFFICIENCY = '0.95'
        HIGHEST_USER_WASTED_PERCENT = '0.20'
        HIGHEST_WASTED_BYTES = '20MB'
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
                    // Get the BUILD_NUMBER parameter
                    def buildNumber = params.BUILD_NUMBER

                    // Define the tagged image
                    def dockerTaggedImage = "${DOCKER_REPOSITORY}:${buildNumber}"
                    // Define the Dive command with parameters
                    def diveCommand = "dive --ci --lowestEfficiency \"${env.LOWEST_EFFICIENCY}\" --highestUserWastedPercent \"${env.HIGHEST_USER_WASTED_PERCENT}\" --highestWastedBytes \"${env.HIGHEST_WASTED_BYTES}\" ${dockerTaggedImage}"

                    // Execute Dive and capture the status
                    def status = sh(script: diveCommand, returnStatus: true)

                    if (status == 0) {
                        echo "Dive analysis completed successfully for ${dockerTaggedImage}."
                    } else {
                        error("Dive found inefficiencies in the ${dockerTaggedImage} Docker image.")
                    }
                }
            }
        }

                stage('Print Environment Variables') {
            steps {
                script {
                    // Execute Dive and capture the output
                    def diveOutput = sh(script: diveCommand, returnStdout: true).trim()

                    // Parse the Dive output to extract and print the desired values
                    def efficiency = (diveOutput =~ /efficiency:\s+([\d.]+ %)/)[0][1]
                    def userWastedPercent = (diveOutput =~ /userWastedPercent:\s+([\d.]+ %)/)[0][1]
                    def wastedBytes = (diveOutput =~ /wastedBytes:\s+([\d,]+ bytes)/)[0][1]

                    echo "Lowest Efficiency: ${efficiency}"
                    echo "Highest User Wasted Percent: ${userWastedPercent}"
                    echo "Highest Wasted Bytes: ${wastedBytes}"
                }
            }
        }
    }
}
