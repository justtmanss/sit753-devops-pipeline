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

                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    bat 'mvnw.cmd verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.qualitygate.wait=true'
                }
            }
        }
    }
}