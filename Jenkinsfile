pipeline {
    agent any

    stages {
        // CÀI JQ TỰ ĐỘNG NẾU CHƯA CÓ (chạy 1 lần là xong mãi mãi)
        stage('Cài jq nếu chưa có') {
            steps {
                sh '''
                    if ! command -v jq >/dev/null 2>&1; then
                        echo "Đang cài jq..."
                        if command -v apt-get >/dev/null; then
                            sudo apt-get update && sudo apt-get install -y jq
                        elif command -v yum >/dev/null; then
                            sudo yum install -y jq
                        elif command -v amazon-linux-extras >/dev/null; then
                            sudo amazon-linux-extras install epel -y && sudo yum install -y jq
                        fi
                    else
                        echo "jq đã có sẵn!"
                    fi
                '''
            }
        }

        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Đã lấy code mới nhất từ GitHub"
            }
        }

        stage('Build Docker Image & Push to ECR') {
            steps {
                script {
                    def buildTag   = "${env.BUILD_NUMBER}"
                    def ecrRepo    = "cp-ecr"
                    def region     = "ap-northeast-2"
                    def accountId  = "591313757404"

                    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com"
                    sh "docker build -t ${ecrRepo}:${buildTag} ."
                    sh "docker tag ${ecrRepo}:${buildTag} ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                    sh "docker push ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                    env.IMAGE_URI = "${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                    echo "Push xong image: ${env.IMAGE_URI}"
                }
            }
        }

        // STAGE CHUẨN NHẤT – DÙNG jq ĐÃ CÀI Ở TRÊN → CHẠY 100%
        stage('Update Task Definition & Deploy to ECS') {
            steps {
                script {
                    def taskFamily   = "taskcongphuc"   // sửa nếu tên khác
                    def clusterName  = "cp-cluster"
                    def serviceName  = "cp-sv"
                    def region       = "ap-northeast-2"

                    sh "aws ecs describe-task-definition --task-definition ${taskFamily} --region ${region} --query 'taskDefinition' --output json > full.json"

                    sh """
                        jq '{
                            family: .family,
                            executionRoleArn: .executionRoleArn,
                            taskRoleArn: .taskRoleArn,
                            networkMode: .networkMode,
                            containerDefinitions: .containerDefinitions,
                            volumes: .volumes,
                            requiresCompatibilities: .requiresCompatibilities,
                            cpu: .cpu,
                            memory: .memory,
                            placementConstraints: (.placementConstraints // empty),
                            tags: (.tags // empty)
                        }' full.json > clean.json
                    """

                    sh """
                        jq --arg img "${env.IMAGE_URI}" '.containerDefinitions[0].image = \$img' clean.json > final.json
                    """

                    def newTaskArn = sh(
                        script: "aws ecs register-task-definition --cli-input-json file://final.json --region ${region} --query 'taskDefinition.taskDefinitionArn' --output text",
                        returnStdout: true
                    ).trim()

                    echo "Task Definition mới: ${newTaskArn}"

                    sh """
                        aws ecs update-service --cluster ${clusterName} --service ${serviceName} --task-definition ${newTaskArn} --force-new-deployment --region ${region}
                    """

                    sh "rm -f full.json clean.json final.json"
                    echo "DEPLOY XONG 100%! Web sẽ mới trong 1-2 phút"
                }
            }
        }
    }

    post {
        success { echo "CI/CD HOÀN HẢO – WEB ĐÃ MỚI!" }
        failure { echo "Lỗi rồi, báo mình ngay nhé!" }
    }
}
