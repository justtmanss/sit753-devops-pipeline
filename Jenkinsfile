pipeline {
    agent any

    stages {

        stage('Build') {
            steps {
                echo 'Building the application...'
                bat 'mvnw.cmd clean package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running automated tests...'
                bat 'mvnw.cmd test'
            }
        }

        stage('Code Quality') {
            steps {
                echo 'Running SonarCloud code quality analysis...'

                withCredentials([
                    string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')
                ]) {
                    bat 'mvnw.cmd verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.qualitygate.wait=true'
                }
            }
        }

        stage('Security') {
            steps {
                echo 'Running Trivy security scan...'

                bat 'C:\\Users\\manas\\Downloads\\trivy_0.74.0_windows-64bit\\trivy.exe fs . --scanners vuln --severity HIGH,CRITICAL --exit-code 1'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application to staging...'
                powershell '.\\scripts\\deploy-staging.ps1'
            }
        }
        stage('Release') {
            steps {
                echo 'Releasing application to production...'
                powershell '.\\scripts\\release-production.ps1'
            }
        }
    }
}