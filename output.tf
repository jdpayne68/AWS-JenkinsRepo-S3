output "jenkins_public_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "Jenkins server public IP"
}
output "jenkins_private_ip" {
  value       = aws_instance.jenkins.private_ip
  description = "Jenkins server private IP"
}
