# ---------------------------------------------------------------------------------------------------------------------
# Proviision AWS environment in any Region for diploma project
# Create :
#	- VPC 
#	- PUBLIC AND PRIVATE SUBNETS
#	- ROUTE TABLE FOR SUBNETS
#	- SECURITY GROUPS FOR SERVICES
#	- DATABASE INSTANCE
#	- JENKINS EC2 INSTANCE
# 	- SONARQUBE EC2 INSTANCE
#	- ELASTIC KUBERNETES SERVICE
#	- AMAZON ECR
#
# Made by Sergei Larin
# ---------------------------------------------------------------------------------------------------------------------

terraform {
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 3.0"
		}	    	    
	}
	backend "s3" {
	  bucket  = "tf-state-bucket-epam-diploma"
	  encrypt = true
	  key     = "terraform.tfstate"
	}
	required_version = "~> 1.0"
}

provider "aws" {
    region = var.default_aws_region
}



data "aws_availability_zones" "working"{}
data "aws_caller_identity" "current" {}
data "aws_region" "current"{}
data "aws_ami" "latest_aws_linux" {
	owners      = ["137112412989"]
	most_recent = true
	filter {
		name  = "name"
		values = [
			"amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2",
		]
	}
}


# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
    cidr_block           = var.vpc_cidr_block
    enable_dns_support   = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink   = "false"
    instance_tenancy     = "default"    
    
	tags =  merge (var.common_tags, {Name = "VPC ${var.vpc_cidr_block}"})
}
# ---------------------------------------------------------------------------------------------------------------------
# PUBLIC AND PRIVATE SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "subnet-public-a" {
    vpc_id                  = aws_vpc.vpc.id
	availability_zone       = data.aws_availability_zones.working.names[0]
    cidr_block              = var.public_subnet_a_cidr_block
    map_public_ip_on_launch = "true" 
	
	tags =  merge (var.common_tags, {Name = "Public subnet A in ${data.aws_availability_zones.working.names[0]}"})
}

resource "aws_subnet" "subnet-public-b" {
    vpc_id                  = aws_vpc.vpc.id
	availability_zone       = data.aws_availability_zones.working.names[1]
    cidr_block              = var.public_subnet_b_cidr_block
    map_public_ip_on_launch = "true" 
	
	tags =  merge (var.common_tags, {Name = "Public subnet B in ${data.aws_availability_zones.working.names[0]}"})
}

resource "aws_subnet" "subnet-private-a" {
    vpc_id                  = aws_vpc.vpc.id
	availability_zone       = data.aws_availability_zones.working.names[0]
    cidr_block              = var.private_subnet_a_cidr_block
	
	tags =  merge (var.common_tags, {Name = "Private subnet A in ${data.aws_availability_zones.working.names[0]}"})
}

resource "aws_subnet" "subnet-private-b" {
    vpc_id                  = aws_vpc.vpc.id
	availability_zone       = data.aws_availability_zones.working.names[1]
    cidr_block              = var.private_subnet_b_cidr_block
	
	tags =  merge (var.common_tags, {Name = "Private subnet B in ${data.aws_availability_zones.working.names[0]}"})
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    
	tags   =  merge (var.common_tags, {Name = "Internet  GateWay"})
}

# ---------------------------------------------------------------------------------------------------------------------
# ROUTE TABLE FOR SUBNETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "public-crt" {
    vpc_id = aws_vpc.vpc.id
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.igw.id
    }
    
	tags   =  merge (var.common_tags, {Name = "Public route table"})
}

resource "aws_route_table" "private-crt" {
    vpc_id = aws_vpc.vpc.id
    
	tags   =  merge (var.common_tags, {Name = "Private route table"})	
}

resource "aws_route_table_association" "crta-public-subnet-a"{
    subnet_id      = aws_subnet.subnet-public-a.id
    route_table_id = aws_route_table.public-crt.id
}

resource "aws_route_table_association" "crta-public-subnet-b"{
    subnet_id      = aws_subnet.subnet-public-b.id
    route_table_id = aws_route_table.public-crt.id
}

resource "aws_route_table_association" "crta-private-subnet-a"{
    subnet_id      = aws_subnet.subnet-private-a.id
    route_table_id = aws_route_table.private-crt.id
}

resource "aws_route_table_association" "crta-private-subnet-b"{
    subnet_id 	   = aws_subnet.subnet-private-b.id
    route_table_id = aws_route_table.private-crt.id
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "allow_ssh_sg" {
	vpc_id = aws_vpc.vpc.id
    name        =  "ssh_by_ip"
    description = "Allow ssh by IP"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.allow_ssh_from_ip]
    }
	  
	egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
	
	tags =  merge (var.common_tags, {Name = "Allow connection from IP"})	
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABASE INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "db_instance" {
	name   = "Database SG"
	vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "allow_db_access" {
	type              = "ingress"
	from_port         = var.port
	to_port           = var.port
	protocol          = "tcp"
	security_group_id = aws_security_group.db_instance.id
	cidr_blocks       = ["0.0.0.0/0"]
}

resource "random_string" "rds_password" {
	length 			 = 12
	special 		 = true
	override_special = "!#$&"
}

resource "aws_ssm_parameter" "rds_password" {
	name 		= var.rds_pass_key
	description = "Master Password for RDS"
	type 		= "SecureString"
	value		= random_string.rds_password.result
}

data "aws_ssm_parameter" "master_rds_password"{
	name 		= var.rds_pass_key
	depends_on = [aws_ssm_parameter.rds_password]
}

resource "aws_db_subnet_group" "db_subnets" {
	name       = "education"
	subnet_ids = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id]
}

resource "aws_db_instance" "default" {
	identifier             = var.name
	allocated_storage      = var.allocated_storage
	engine                 = var.engine_name
	engine_version         = var.engine_version
	port                   = var.port
	name                   = var.db_name
	username               = var.db_username
	password               = data.aws_ssm_parameter.master_rds_password.value
	instance_class         = var.instance_class
	db_subnet_group_name   = aws_db_subnet_group.db_subnets.id
	vpc_security_group_ids = [aws_security_group.db_instance.id]
	skip_final_snapshot    = true
	publicly_accessible    = true

	tags =  merge (var.common_tags, {Name = "RDS database"})	
}

resource "aws_key_pair" "ssh-key" {
	key_name   = "aws-key"
	public_key = file(var.aws_public_key)
}

# ---------------------------------------------------------------------------------------------------------------------
# JENKINS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "jenkins_sg" {
    vpc_id = aws_vpc.vpc.id
    name   = "Jenkins security group"
	description = "security group for Jenkins"

    dynamic "ingress" {
		for_each = var.jenkins_ports
		content {
			from_port = ingress.value
			to_port = ingress.value
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]
		}
    }
	
	egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
	
	tags =  merge (var.common_tags, {Name = "Allow connection to Jenkins"})	
}

data "local_file" "sonar-token" {
    filename = "jenkins_scripts/sonar-token.txt"
	depends_on = [null_resource.preparefile]
}

resource "aws_instance" "jenkins" {
    ami                    = data.aws_ami.latest_aws_linux.id
    instance_type          = var.instance_type
    subnet_id              = aws_subnet.subnet-public-a.id
    security_groups	  	   = [aws_security_group.jenkins_sg.id, aws_security_group.allow_ssh_sg.id]
	key_name			   = aws_key_pair.ssh-key.key_name

    connection {
		type         = "ssh"
		user         = "ec2-user"
		private_key  = file(var.aws_private_key)
		host         = aws_instance.jenkins.public_ip
	}

	provisioner "file" {
		source      = "jenkins_scripts/Dockerfile.jenkins"
		destination = "Dockerfile.jenkins" 
    }
	provisioner "file" {
		source      = "jenkins_scripts/jenkins.yaml"
		destination = "jenkins.yaml" 
    }
	provisioner "file" {
		source      = "jenkins_scripts/plugins.txt"
		destination = "plugins.txt" 
    }
	provisioner "file" {
		source      = "jenkins_scripts/.env"
		destination = ".env" 
    }
	provisioner "file" {
		source      = "jenkins_scripts/.env_jenkins"
		destination = ".env_jenkins" 
    }
	provisioner "file" {
		source      = "jenkins_scripts/docker-compose.yaml"
		destination = "docker-compose.yaml" 
    }
		provisioner "file" {
		source      = "jenkins_scripts/sonar-token.txt"
		destination = "sonar-token.txt" 
    }
	
    provisioner "remote-exec" {
		inline = [
			"sudo yum update -y",
			"sudo amazon-linux-extras install docker -y",
			"sudo yum install docker -y",
			"sudo service docker start",
			"sudo systemctl enable docker",
			"sudo usermod -a -G docker ec2-user",
			"sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
			"sudo chmod +x /usr/local/bin/docker-compose",
			"sed -i 's/account_id/${data.aws_caller_identity.current.account_id}/g' .env_jenkins",
			"sed -i 's/region_name/${data.aws_region.current.name}/g' .env_jenkins",
			"sed -i 's/pg_entrypoint/${aws_db_instance.default.address}/g' .env_jenkins",
			"sed -i 's/git_token/${var.github_token}/g' .env_jenkins",
			"sed -i 's/pg_password/${data.aws_ssm_parameter.master_rds_password.value}/g' .env_jenkins",
			"sed -i 's/aws_id/${var.aws_id}/g' .env_jenkins",
			"sed -i 's|aws_key|${var.aws_key}|g' .env_jenkins",
			"sed -i 's/sonar_ip/${aws_instance.sonar.private_ip}/g' .env_jenkins",
			"sed -i 's/sonar_token/${data.local_file.sonar-token.content}/g' .env_jenkins",
			"sed -i 's/jenkins_ip/${aws_instance.jenkins.public_ip}/g' .env_jenkins",
			"sudo /usr/local/bin/docker-compose up --detach"
		]
    }	
	
	tags =  merge (var.common_tags, {Name = "Jenkins Server"})	
	
	lifecycle {
		ignore_changes = [
			security_groups,
		]
    }
	
	depends_on = [
		aws_ecr_repository.ecr_registry,
		aws_db_instance.default,
		aws_ssm_parameter.rds_password,
		aws_instance.sonar,
		null_resource.preparefile
		]
}

# ---------------------------------------------------------------------------------------------------------------------
# SONARQUBE INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "sonar_sg" {
	vpc_id = aws_vpc.vpc.id
    name        =  "Sonar security group"
    description = "security group for Sonar"

    ingress {
        from_port   = 9000
        to_port     = 9000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
	  
	egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
	
	tags =  merge (var.common_tags, {Name = "Allow connection to SonarQube"})	
}

resource "aws_instance" "sonar" {
    ami                    = data.aws_ami.latest_aws_linux.id
    instance_type          = var.instance_type
    subnet_id              = aws_subnet.subnet-public-a.id
    security_groups		   = [aws_security_group.sonar_sg.id, aws_security_group.allow_ssh_sg.id]
	key_name			   = aws_key_pair.ssh-key.key_name
	
    connection {
		type         = "ssh"
		user         = "ec2-user"
		private_key  = file(var.aws_private_key)
		host         = aws_instance.sonar.public_ip
	}
	
	provisioner "file" {
		source      = "sonar/docker-compose.yaml"
		destination = "docker-compose.yaml" 
    }
	
	provisioner "file" {
		source      = "sonar/.env"
		destination = ".env" 
    }

    provisioner "remote-exec" {
		inline = [
			"sudo yum update -y",
			"sudo amazon-linux-extras install docker -y",
			"sudo yum install docker -y",
			"sudo service docker start",
			"sudo systemctl enable docker",
			"sudo usermod -a -G docker ec2-user",
			"sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
			"sudo chmod +x /usr/local/bin/docker-compose",
			"sudo sysctl -w vm.max_map_count=262144",
			"sudo /usr/local/bin/docker-compose up --detach"
		]
    }
	
	
	tags =  merge (var.common_tags, {Name = "SonarQube Server"})	
	
	lifecycle {
		ignore_changes = [
			security_groups,
		]
    }
	
}

#-----------------------------------------------------
# DELAY TO START SONAR
#-----------------------------------------------------

resource "time_sleep" "delay" {
  depends_on = [aws_instance.sonar]

  create_duration = "60s"
}

	
resource "null_resource" "after" {
	provisioner "local-exec" {
		command  = "curl -u admin:admin -d name=my_token -X POST http://${aws_instance.sonar.public_ip}:9000/api/user_tokens/generate -o jenkins_scripts/sonar-token.txt"
	}
	depends_on = [time_sleep.delay]
}

resource "null_resource" "preparefile" {
	provisioner "local-exec" {
		command  = "python jenkins_scripts/cut_file.py"
	}
	depends_on = [null_resource.after]
}


# ---------------------------------------------------------------------------------------------------------------------
# ELASTIC KUBERNETES SERVICE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "iam-role-eks-cluster" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
	role       = aws_iam_role.iam-role-eks-cluster.name
}


resource "aws_security_group" "eks-cluster" {
	name        = "eks-cluster-SG"
	vpc_id      = aws_vpc.vpc.id


	egress {                  
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {                 
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_eks_cluster" "eks_cluster" {
	name     = var.k8s_name
	role_arn =  aws_iam_role.iam-role-eks-cluster.arn
	version  = var.k8s_version

	vpc_config {
		security_group_ids = [aws_security_group.eks-cluster.id, aws_security_group.db_instance.id]
		subnet_ids         = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id] 
    }

	depends_on = [aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy]
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
	role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
	role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
	role       = aws_iam_role.eks_nodes.name
}


resource "aws_eks_node_group" "node" {
	cluster_name              = aws_eks_cluster.eks_cluster.name
	node_group_name           = "k8s_node_group"
	node_role_arn             = aws_iam_role.eks_nodes.arn
	instance_types  		  = [var.k8s_node_type]
	subnet_ids      		  = [aws_subnet.subnet-public-a.id, aws_subnet.subnet-public-b.id]

	tags =  merge (var.common_tags, {Name = "Node k8s"})

	scaling_config {
		desired_size = 1
		max_size     = 2
		min_size     = 1
	}

	update_config {
        max_unavailable = 2
    }

	depends_on = [
		aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
		aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
		aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
	]
}


data "aws_eks_cluster" "cluster" {
	name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
	name = aws_eks_cluster.eks_cluster.name
}

# ---------------------------------------------------------------------------------------------------------------------
# AMAZON ECR
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "ecr_registry" {
	name                 = "diploma"
	image_tag_mutability = "MUTABLE"

	image_scanning_configuration {
		scan_on_push = false
	}
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr_registry.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last untagged image",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        },
		{
            "rulePriority": 2,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["dev-"],
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

