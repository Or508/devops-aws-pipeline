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
                    [pattern: 'vockey.pem', type: 'EXCLUDE'],
                    [pattern: 'terraform/terraform.tfstate', type: 'EXCLUDE'],
                    [pattern: 'terraform/terraform.tfstate.backup', type: 'EXCLUDE'],
                    [pattern: 'terraform/.terraform/**', type: 'EXCLUDE']
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
                        ..\\terraform.exe apply -auto-approve -no-color -var="aws_key_name=%AWS_KEY_NAME%"
                    '''
                }
            }
        }
        stage('Deploy Application via SSH') {
            steps {
                powershell '''
                    Set-Location terraform
                    $TARGET_IP = (../terraform.exe output -no-color -raw instance_public_ip).Trim()
                    Set-Location ..
                    
                    if (-not $TARGET_IP) {
                        Write-Error "Error: Could not fetch Target IP from Terraform!"
                        exit 1
                    }
                    
                    Write-Host "Deploying directly to Target IP: $TARGET_IP"
                    
                    # Create a clean, isolated copy of the key inside the current temporary workspace
                    $LocalKey = "$env:WORKSPACE/vockey_isolated.pem"
                    Copy-Item "C:/jenkins_keys/vockey.pem" $LocalKey -Force
                    
                    # Strip ALL permissions and grant Full Control ONLY to the specific user running this Jenkins process
                    $CurrentFullUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                    icacls $LocalKey /inheritance:r
                    icacls $LocalKey /grant:r "${CurrentFullUser}:F"
                    
                    # Run Native SSH and SCP using this strictly isolated key file
                    ssh -o StrictHostKeyChecking=no -i $LocalKey ubuntu@${TARGET_IP} "sudo chown -R ubuntu:ubuntu /var/www/html"
                    scp -o StrictHostKeyChecking=no -i $LocalKey -r ansible/files/web/* ubuntu@${TARGET_IP}:/var/www/html/
                    
                    # Cleanup
                    Remove-Item $LocalKey -Force
                    
                    Write-Host "Deployment Completed Successfully!"
                '''
            }
        }
    }
}
