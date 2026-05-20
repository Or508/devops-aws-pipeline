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
                        ..\\terraform.exe destroy -auto-approve -var="aws_key_name=vockey"
                    '''
                }
            }
        }
        stage('Deploy Application via SSH') {
            steps {
                powershell '''
                    $TARGET_IP = (terraform.exe output -no-color -raw instance_public_ip).Trim()
                    if (-not $TARGET_IP) {
                        Write-Error "Error: Could not fetch Target IP from Terraform!"
                        exit 1
                    }
                    
                    Write-Host "Deploying directly to Target IP: $TARGET_IP"
                    
                    # Run Native SSH and SCP using the clean PowerShell variable
                    ssh -o StrictHostKeyChecking=no -i "C:/Users/User/Desktop/devops-jenkins-terraform-ansible/vockey.pem" ubuntu@${TARGET_IP} "sudo chown -R ubuntu:ubuntu /var/www/html"
                    scp -o StrictHostKeyChecking=no -r -i "C:/Users/User/Desktop/devops-jenkins-terraform-ansible/vockey.pem" ansible/files/web/* ubuntu@${TARGET_IP}:/var/www/html/
                    
                    Write-Host "Deployment Completed Successfully!"
                '''
            }
        }
    }
}
