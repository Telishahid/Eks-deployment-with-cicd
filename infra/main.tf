data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "available-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_eks_cluster" "shahid-cluster" {
  name     = "shahid-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = data.aws_subnets.available-subnets.ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.shahid-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.shahid-cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.shahid-cluster.name
  node_group_name = "pc-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = data.aws_subnets.available-subnets.ids
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t3.micro"]
  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
    ]  
}

resource "aws_eks_access_entry" "shahidteli-admin" {
  cluster_name  = aws_eks_cluster.shahid-cluster.name
  principal_arn = "arn:aws:iam::861276093737:user/shahidteli"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "shahidteli-admin-policy" {
  cluster_name  = aws_eks_cluster.shahid-cluster.name
  principal_arn = aws_eks_access_entry.shahidteli-admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
