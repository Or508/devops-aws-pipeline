pipeline {
    agent any
    
    environment {
        AWS_KEY_NAME = "${params.AWS_KEY_NAME}"
    }
    
    parameters {
        string(name: 'AWS_KEY_NAME', defaultValue: 'vockey', description: 'Name of the AWS EC2 Key Pair')
    }
    
    stages {
        stage('Checkout') {
            steps {
                cleanWs(deleteDirs: true, patterns: [
                    [pattern: 'terraform.exe', type: 'EXCLUDE'],
                    [pattern: 'vockey.pem', type: 'EXCLUDE']
                ])
                checkout scm
            }
        }
        stage('Terraform Infra Provisioning') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat '''
                        cd terraform
                        ..\\terraform.exe init
                        ..\\terraform.exe apply -auto-approve -var="aws_key_name=%AWS_KEY_NAME%"
                    '''
                }
            }
        }
        stage('Deploy Application via SSH') {
            steps {
                bat '''
                    @echo off
                    echo Deploying files directly to AWS EC2 via Native SSH...

                    cd terraform
                    for /f "delims=" %%i in ('..\terraform.exe output -raw instance_public_ip') do set EC2_IP=%%i
                    cd ..

                    REM Disabling strict host key checking for automated deployment
                    ssh -o StrictHostKeyChecking=no -i vockey.pem ubuntu@%EC2_IP% "sudo chown -R ubuntu:ubuntu /var/www/html"

                    REM Copy web files directly to the server
                    scp -o StrictHostKeyChecking=no -r -i vockey.pem ansible\files\web\* ubuntu@%EC2_IP%:/var/www/html/

                    echo Deployment successful!
                '''
            }
        }
    }
}
