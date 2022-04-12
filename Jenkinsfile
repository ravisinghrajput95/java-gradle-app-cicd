pipeline{
    agent any
    stages{
        stage("Code Checkout"){
            steps{
                echo "[*] INFO : Checking out latest code from git"
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/ravisinghrajput95/java-gradle-app-cicd.git'
            }
        }

        stage("Git-secrets"){
            steps{
                echo "[*] INFO : Validating commited secrets on to the Version Control"
                sh 'rm trufflehog || true'
                sh 'docker run gesellix/trufflehog --json https://github.com/ravisinghrajput95/java-gradle-app-cicd.git > trufflehog'
                sh 'cat trufflehog'
            }
        }

        stage("Unit tests"){
            steps{
                echo "[*] INFO : Performing unit tests on the Source code"
                sh 'chmod +x gradlew'
                sh './gradlew test'
            }
        }

        stage("Sonar Analysis"){
            steps{
                echo "[*] INFO : Sonar Analysis is in progress"
                script{
                    withSonarQubeEnv(credentialsId: 'sonartoken'){
                        sh './gradlew sonarqube'
                    }
                }
            }
        }

        stage("Quality Gates"){
            steps{
                echo "[*] INFO : Quality Gates verification check"
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Source Composition Analysis"){
            steps{
                echo "[*] INFO : Performing Source Composition Analysis"
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-checker'
            }
        }
    }
    post{
        always{
            echo "[EMAIL] Email  notifications"
            mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
        }
        success{
            echo "[SUCCESS] Pipeline executed successfully  "
            slackSend color: "good", message: "Status: Pipeline executed successfully  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        failure{
            echo "[FAILED] pipeline execution failed   "
            slackSend color: "danger", message: "Status: pipeline execution failed | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "

        }
        unstable{
            echo "[UNSTABLE] Build is unstable   "
            slackSend color: "yellow", message: "Status: Build is unstable  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        aborted{
            echo "[UNSTABLE] Build was aborted   "
            slackSend color: "yellow", message: "Build was aborted  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
    }
}