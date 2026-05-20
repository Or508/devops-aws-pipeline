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
                    echo Fetching target IP from Terraform...
                    for /f "tokens=*" %%i in ('terraform.exe output -raw instance_public_ip') do set TARGET_IP=%%i
                    
                    if "%TARGET_IP%"=="" (
                        echo Error: Could not fetch Target IP from Terraform!
                        exit 1
                    )
                    
                    echo Deploying to Target IP: %TARGET_IP%
                    
                    rem Using forward slashes for key and asset paths to bypass Groovy string escape issues
                    ssh -o StrictHostKeyChecking=no -i ../vockey.pem ubuntu@%TARGET_IP% "sudo chown -R ubuntu:ubuntu /var/www/html"
                    scp -o StrictHostKeyChecking=no -r -i ../vockey.pem ansible/files/web/* ubuntu@%TARGET_IP%:/var/www/html/
                    
                    echo Deployment Completed Successfully!
                '''
            }
        }
    }
}
