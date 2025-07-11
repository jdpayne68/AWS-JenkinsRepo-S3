pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Set AWS Credentials') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
                    aws sts get-caller-identity
                    '''
                }
            }
        }
        stage('Initialize Terraform') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Validate Terraform') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Plan Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform plan -out=tfplan
                    '''
                }
            }
        }
        stage('Apply Terraform') {
            steps {
                input message: "Approve Terraform Apply?", ok: "Deploy"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
        stage('Checkout GitHub Code') {
            steps {
                git branch: 'main', url: 'https://github.com/jdpayne68/AWS-JenkinsRepo-S3.git'
            }
        }
        stage('Docker Run Example Scan') {
            steps {
                sh '''
                docker run --rm --pull=always \
                -u $(id -u) -v ${WORKSPACE}:${WORKSPACE}:rw -w ${WORKSPACE} \
                -e BURP_CONFIG_FILE_PATH=${WORKSPACE}/burp_config.yml \
                public.ecr.aws/portswigger/enterprise-scan-container:latest
                '''
            }
        }
        
        stage('Dastardly Scan') {
            steps {
                sh '''
                docker run --rm --user $(id -u) -v ${WORKSPACE}:${WORKSPACE}:rw \
                -e BURP_START_URL=https://ginandjuice.shop/ \
                -e BURP_REPORT_FILE_PATH=${WORKSPACE}/dastardly-report.xml \
                public.ecr.aws/portswigger/dastardly:latest
                '''
            }
        }
        stage('Destroy Terraform') {
            steps {
                input message: "Do you want to destroy the infrastructure?", ok: "Destroy"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform destroy -auto-approve
                    '''
                }
            }
        }
    }
    post {
        always {
            junit testResults: 'burp_junit_report.xml', skipPublishingChecks: true, allowEmptyResults: true
            // junit testResults: 'dastardly-report.xml', skipPublishingChecks: true, allowEmptyResults: true
            cleanWs()
        }
    }
}