// =====================================================================
// KHAI BÁO CÁC BIẾN CẤU HÌNH (THAY THẾ CHỖ BỊ CHẶN)
// =====================================================================
def ecrRepository = "cp-ecr"       // Ví dụ: ecommerce-backend
def ecsCluster = "cp-cluster"           // Tên Cluster ECS của bạn
def ecsService = "cp-sv"           // Tên Service ECS của bạn
def taskDefinitionName = "taskcongphuc"  // Tên Task Definition gốc (VD: backend-task)
def containerName = "congphucontai" // Tên Container trong Task Definition (Lấy từ Task Def JSON)
def awsRegion = "ap-northeast-2"                 // Region của bạn (VD: ap-southeast-1)
def awsAccountId = "591313757404"                // ID tài khoản AWS của bạn (Đã có sẵn)

pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                echo '1. Lấy mã nguồn mới nhất...'
                checkout scm 
            }
        }

        stage('Build and Push Image to ECR') {
            steps {
                echo '2. Đăng nhập ECR và Build Image...'
                // Tạo Image Tag duy nhất dựa trên Build Number
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                }
                
                // Đăng nhập ECR (Sử dụng IAM Role gắn với EC2 Jenkins)
                sh "aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com"

                // Build Image Docker (Sử dụng Dockerfile trong Repo)
                sh "docker build -t ${ecrRepository}:${env.IMAGE_TAG} ."

                // Gắn Tag hoàn chỉnh (Fully Qualified ECR URI) và Push lên ECR
                sh "docker tag ${ecrRepository}:${env.IMAGE_TAG} ${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${ecrRepository}:${env.IMAGE_TAG}"
                sh "docker push ${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${ecrRepository}:${env.IMAGE_TAG}"
            }
        }

        stage('Deploy to ECS') {
            steps {
                echo '3. Cập nhật Task Definition và ECS Service...'
                
                script {
                    // 3a. Xác định URI Image mới
                    def newImageUri = "${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com/${ecrRepository}:${env.IMAGE_TAG}"

                    // 3b. Lấy Task Definition hiện tại (LƯU Ý: Phải cài đặt JQ trên Jenkins EC2)
                    def taskDefJson = sh(
                        script: "aws ecs describe-task-definition --task-definition ${taskDefinitionName} --region ${awsRegion} --query 'taskDefinition'",
                        returnStdout: true
                    )
                    
                    // 3c. Dùng JQ để sửa URI Image và dọn dẹp các trường không cần thiết
                    // [0] đại diện cho container đầu tiên trong Task Definition
                    def newTaskDefJson = sh(
                        script: "echo \"${taskDefJson}\" | jq 'del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | .containerDefinitions[0].image=\"${newImageUri}\"' > updated-task-def.json",
                        returnStdout: true
                    )
                    
                    // 3d. Đăng ký Task Definition mới với URI Image cập nhật
                    sh "aws ecs register-task-definition --cli-input-json file://updated-task-def.json --region ${awsRegion}"

                    // 3e. Cập nhật ECS Service để sử dụng Task Definition mới nhất
                    sh "aws ecs update-service --cluster ${ecsCluster} --service ${ecsService} --force-new-deployment --region ${awsRegion}"
                }
                echo 'Triển khai lên ECS đã hoàn tất.'
            }
        }
    }
}


