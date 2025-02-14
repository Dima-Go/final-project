# Output the cluster endpoint
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# Output the cluster kubeconfig command
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1"
}

# Output the EC2 instance public IP
output "ec2_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
} 

# Output the Jenkins EC2 instance initial password
output "jenkins_initial_password" {
  value = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  
}
