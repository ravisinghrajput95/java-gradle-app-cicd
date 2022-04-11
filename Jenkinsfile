pipeline{
    agent any
    stages{
        stage("Code Checkout"){
            steps{
                echo "[*] INFO : Checking out latest code from git"
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/ravisinghrajput95/java-gradle-app-cicd.git'
            }
        }

        stage("Sonar Analysis"){
            steps{
                echo "[*] INFO : Sonar Analysis is in progress"
                script{
                    withSonarQubeEnv(credentialsId: 'sonartoken'){
                        sh 'chmod +x gradlew'
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
    }
    post{
        always{
            echo "========always========"
        }
        success{
            echo "========pipeline executed successfully ========"
        }
        failure{
            echo "========pipeline execution failed========"
        }
    }
}