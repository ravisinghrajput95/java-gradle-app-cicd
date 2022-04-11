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

        stage("Source Composition Analysis"){
            steps{
                echo "[*] INFO : Performing Source Composition Analysis"
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-checker'
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