terraform {
  required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
        region = "us-east-1"
        }
    }
}

resource "aws_s3_bucket" "private" {
    bucket = "qzqsm"
    acl    = "private"

    versioning {
        enabled = true
    }
}

resource "aws_vpc" "qzqsm-system-proto" {
    cidr_block = "192.178.7.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.qzqsm-system-proto.id
    cidr_block = "192.178.7.128/25"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.qzqsm-system-proto.id
    cidr_block = "192.178.7.0/25"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.qzqsm-system-proto.id
}

resource "aws_route_table" "ec2" {
    vpc_id = aws_vpc.qzqsm-system-proto.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        }
}

resource "aws_route_table_association" "ec2" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.ec2.id
}

resource "aws_security_group" "ec2" {
  name        = "ec2"
  vpc_id      = aws_vpc.qzqsm-system-proto.id

    ingress {
    description = "internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.qzqsm-system-proto.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "qzqsm" {
    vpc = true
}

resource "aws_key_pair" "main" {
  key_name   = "aws-qzqsm-key"
}

/*
resource "aws_instance" "qzqsm" {
  ami = "ami-02354e95b39ca8dec"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = false
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
}

resource "aws_eip_association" "qzqsm" {
  instance_id   = aws_instance.qzqsm.id
  allocation_id = aws_eip.qzqsm.id
}
*/

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public2.id]
}

resource "aws_db_instance" "qzqsmdb" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "10.9"
  instance_class       = "db.t3.micro"
  availability_zone    = "us-east-1c"
  publicly_accessible  = true
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.main.name
//  security_group_names = ["${aws_security_group.ec2.id}"]
}
