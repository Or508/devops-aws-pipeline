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
                    echo Exporting clean IP from Terraform to temporary file...
                    terraform.exe output -no-color -raw instance_public_ip > ip.txt
                    
                    echo Reading IP from file...
                    set /p TARGET_IP=<ip.txt
                    
                    rem Clean up the temporary file
                    del ip.txt
                    
                    if "%TARGET_IP%"=="" (
                        echo Error: Could not read Target IP!
                        exit 1
                    )
                    
                    echo Deploying directly to Target IP: %TARGET_IP%
                    
                    rem Deploying using OpenSSH with absolute permanent key path
                    ssh -o StrictHostKeyChecking=no -i "C:/Users/User/Desktop/devops-jenkins-terraform-ansible/vockey.pem" ubuntu@%TARGET_IP% "sudo chown -R ubuntu:ubuntu /var/www/html"
                    scp -o StrictHostKeyChecking=no -r -i "C:/Users/User/Desktop/devops-jenkins-terraform-ansible/vockey.pem" ansible/files/web/* ubuntu@%TARGET_IP%:/var/www/html/
                    
                    echo Deployment Completed Successfully!
                '''
            }
        }
    }
}
