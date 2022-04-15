def getVersion(){
    def commitHash =  sh returnStdout: true, script: 'git rev-parse --short HEAD'
    return commitHash
}

pipeline{
    agent any

    options{
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
    }

    environment{
        GIT_COMMIT_HASH = getVersion()
    }

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
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage("Docker build"){
            steps{
                echo "[*] INFO : Docker build in progress.."
                sh 'docker build -t 34.118.94.54:8082/java_gradle:$GIT_COMMIT_HASH . '
            }
        }

        stage("Image Scan"){
            steps{
                echo "[*] INFO : Scanning images using Trivy.."
                sh 'trivy image 34.118.94.54:8082/java_gradle:$GIT_COMMIT_HASH '
            }
        }

        stage("Push image to Nexus"){
            steps{
                echo "[*] INFO : Pushing image to Nexus.."
                script{
                    withCredentials([string(credentialsId: 'nexus', variable: 'nexus')]) {
                        sh '''
                          docker login -u admin -p $nexus 34.118.94.54:8082/java_gradle:$GIT_COMMIT_HASH
                          docker push 34.118.94.54:8082/java_gradle:$GIT_COMMIT_HASH
                        '''
                    }
                }
            }
        }

        stage("Teardown"){
            steps{
                echo "[*] INFO : Removing Docker images after they are pushed to Nexus"
                sh ''' 
                  docker rmi 34.118.94.54:8082/java_gradle:$GIT_COMMIT_HASH
                  docker image prune -f
                '''
            }
        }

        stage("Helm charts config validation"){
            steps{
                echo "[*] INFO : Validating misconfigs as per policies in Datree"
                script{
                    dir('helm-charts/'){
                        withEnv(['DATREE_TOKEN=ao1RpL3G3LMRL6eucy37hv']){
                            sh 'helm datree test java-app/'
                        }
                    }
                }
            }
        }

        stage("Push Helm charts to Nexus"){
            steps{
                echo "[*] INFO : Pushing Helm charts to Nexus"
                script{
                    withCredentials([string(credentialsId: 'nexus', variable: 'nexus')]) {
                        dir("helm-charts"){
                          sh '''
                            chartversion=$(helm show chart java-app | grep version | cut -d: -f 2 | tr -d ' ')
                            tar -czvf  java-app-${chartversion}.tgz java-app/
                            curl -u admin:$nexus http://34.118.94.54:8081/repository/java-gradle-helm-hosted/ --upload-file java-app-${chartversion}.tgz -v
                        '''

                    }
                }
            }
        }
    }    

        stage("Approval"){
            steps{
                script{
                    timeout(10) {
                        mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployment request <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
                        input(id: "Deploy Gate", message: "Deploy ${params.project_name}?", ok: 'Deploy')
                    }
                }
            }
        }

        stage("Deploy to GKE cluster"){
            steps{
                script{
                    withCredentials([kubeconfigFile(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]) {
                        dir("helm-charts/"){
                            sh 'helm upgrade --install --set image.repository="34.118.94.54:8082/java_gradle" --set image.tag="${GIT_COMMIT_HASH}" java-gradle java-app/ ' 
                        }
                    }
                }
            }
        }

          
    }
    post{
        always{
            echo "[ALWAYS] Email  notifications"
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
            echo "[ABORTED] Build was aborted   "
            slackSend color: "yellow", message: "Status: Build was aborted  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
    }
}
