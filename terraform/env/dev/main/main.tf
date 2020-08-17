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
    description = "home"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["223.134.247.32/32"]
  }

    ingress {
    description = "pbl"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7VjTU93iZLvFVTRAJqf8fylM1I6MDhfgnkTcEdIkVixGNu7saiXcyOX+b25r1T6UpqJG46TQfPOPwLwe2hD0/JKDgirHzQYD3Gf4b8ILnqiQSD8ujx5E7iaY5rnHBTqlx9DmQ4hVgoSYALBSdnLl1LPV40HXSEAUUHePFW+GPnmskTq25JoeB7BH8+EBcjLsDSQcuAEVorQR4fQBDALYxQGOtOJSAB6CY+iKsZve1rGx2BYHkCbg/S80M+qRJDPZukfcRhUla4ZGxl/d/21gRP0Te5QZFlUJJaK8G6DsPLKgKuLwM898QAj79Yj04d4xC5tbZ2zkyRi6Nr1QYOgvpqqB3KzO4nZwIC3lS56CpYRVeXfdyQx5uBbhdUF50a4PlCIQHxZOreA955yecoknam78NX7yxsxdM83ogQOP5o6OgJRS3moNESSQbDEwJ1mKONjGEo9WxY7XQ9oZQDtqYkW9JnII8W7HoM1j+64morc7rUlJbpU0Lb7aDjrfrIZiB2VilDBLw13ehw10JO7j02KSVJ5XIjyhoHjbcCqGo8t9lk1eA44pP+JO05f3+hFwqXdqSolZpdC2eUHZQbn2JBpT0vD9kDeKCPK1iU5zQsK444BEI/LbSBNj+TMSZez/l6kLLsQFV3x/5hmPQwF5yICH54k7oU8hYjl1eIAToQw== hiro6t@h-sh3i0x-2.local"
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
  name                 = "qzqsmdb"
  availability_zone    = "us-east-1c"
  publicly_accessible  = true
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}
