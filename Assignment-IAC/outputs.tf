data "aws_availability_zones" "available" {
  state = "available"
}
[ec2-user@ip-172-31-36-61 terraform]$ cat outputs.tf 

output "cluster_name" {
  value = aws_eks_cluster.mycluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.mycluster.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.mycluster.certificate_authority[0].data
}