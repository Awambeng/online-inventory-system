terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "online-inventory-system" {
  ami           = "ami-00beae93a2d981137"
  instance_type = "t2.micro"
  key_name      = "my-aws-key-pair"

  vpc_security_group_ids = [aws_security_group.new_security_group.id]
  
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/my-aws-key-pair.pem")
    host        = self.public_ip
  }

 provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install -y docker",
        "sudo systemctl start docker",
        "sudo docker run -d --name postgres_db -e POSTGRES_DB=oisdb -e POSTGRES_PASSWORD=root -e POSTGRES_USER=root -p 5432:5432 postgres:13",
        "sudo docker run -d --name adminer -p 8080:8080 adminer",
        "sudo docker run -d --name online-inventory-system -p 5000:5000 awambeng/online-inventory-system:latest"
    ]
  }

  tags = {
    Name = "online-inventory-system"
  }
}

resource "aws_security_group" "new_security_group" {
  name_prefix = "example-sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
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
