provider "aws" {
  region = "us-west-1"
}

#vpc
resource "aws_vpc" "fitapp" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "fitapp"
  }

}
#Subnet 1A
resource "aws_subnet" "public_instance" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_instance"
  }

}

resource "aws_subnet" "private_instance1" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.16.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_instance1"
  }

}
resource "aws_subnet" "private_instance2" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.32.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_instance2"
  }

}

#Subnet 1C
resource "aws_subnet" "public_instance1c" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_instance1c"
  }

}

resource "aws_subnet" "private_instance1c" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.48.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_instance1c"
  }

}
resource "aws_subnet" "private_instance2c" {
  vpc_id                  = aws_vpc.fitapp.id
  cidr_block              = "10.0.64.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_instance2c"
  }

}
#IGW
resource "aws_internet_gateway" "fitapp_igw" {
  vpc_id = aws_vpc.fitapp.id

  tags = {
    Name = "internet gateway"
  }

}

#Nat Gateway
resource "aws_eip" "eip_main" {

}

resource "aws_nat_gateway" "gateway_private" {
  allocation_id = aws_eip.eip_main.id
  subnet_id     = aws_subnet.public_instance.id

  tags = {
    Name = "gateway_private"
  }

}

# Route public subnet
resource "aws_route_table" "public-routetable" {
  vpc_id = aws_vpc.fitapp.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fitapp_igw.id
  }

  tags = {
    Name = "public_route"
  }


}



resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_instance.id
  route_table_id = aws_route_table.public-routetable.id

}

resource "aws_route_table_association" "public_assoc1c" {
  subnet_id      = aws_subnet.public_instance1c.id
  route_table_id = aws_route_table.public-routetable.id

}

#private route

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.fitapp.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway_private.id
  }

  tags = {
    Name = "private_route"
  }

}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_instance1.id
  route_table_id = aws_route_table.private_route.id

}

resource "aws_route_table_association" "private_assoc1c" {
  subnet_id      = aws_subnet.private_instance1c.id
  route_table_id = aws_route_table.private_route.id

}

#3 tier app

#public 1A
resource "aws_instance" "public_webserver" {
  ami                         = "ami-04fdea8e25817cd69"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_instance.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]

  tags = {
    Name = "public_webserver"
  }

}
#public 1C
resource "aws_instance" "public_webserver1c" {
  ami                         = "ami-04fdea8e25817cd69"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_instance1c.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]


  tags = {
    Name = "public_webserver1c"
  }

}
#sg public
resource "aws_security_group" "public_sg" {
  name        = "public access"
  description = "allow access to public-server"
  vpc_id      = aws_vpc.fitapp.id

  tags = {
    Name = "public_sg"

  }

  ingress {
    from_port   = 80
    to_port     = 80
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
#fitapp instance 1a
resource "aws_instance" "private_fitapp" {
  ami                         = "ami-04fdea8e25817cd69"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.private_instance1.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # Update the package list and install Apache
    sudo yum update -y
    sudo yum install -y httpd

    # Install CloudWatch Agent
    sudo yum install -y amazon-cloudwatch-agent

    # Create CloudWatch Agent Configuration
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/httpd/access_log",
                "log_group_name": "/aws/ec2/instance/httpd-access",
                "log_stream_name": "{instance_id}-access-log",
                "timestamp_format": "%d/%b/%Y:%H:%M:%S %z",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/httpd/error_log",
                "log_group_name": "/aws/ec2/instance/httpd-error",
                "log_stream_name": "{instance_id}-error-log",
                "timestamp_format": "%d/%b/%Y:%H:%M:%S %z",
                "timezone": "UTC"
              }
            ]
          }
        }
      }
    }
    EOT

    # Start CloudWatch Agent
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

    # Ensure CloudWatch Agent starts on boot
    sudo systemctl enable amazon-cloudwatch-agent

    # Start and enable Apache to run on boot
    sudo systemctl start httpd
    sudo systemctl enable httpd

    # Create a simple HTML page
    echo "<html>
    <head>
      <title>Fitness App</title>
    </head>
    <body>
      <h1>This is my fitness app1c</h1>
    </body>
    </html>" | sudo tee /var/www/html/index.html

    # Restart Apache to ensure the page loads
    sudo systemctl restart httpd
  EOF

  tags = {
    Name = "private_fitapp"
  }
}



#fitapp instance 1c
resource "aws_instance" "private_fitapp1c" {
  ami                         = "ami-04fdea8e25817cd69"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.private_instance1c.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # Update the package list and install Apache
    sudo yum update -y
    sudo yum install -y httpd

    # Install CloudWatch Agent
    sudo yum install -y amazon-cloudwatch-agent

    # Create CloudWatch Agent Configuration
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/httpd/access_log",
                "log_group_name": "/aws/ec2/instance/httpd-access",
                "log_stream_name": "{instance_id}-access-log",
                "timestamp_format": "%d/%b/%Y:%H:%M:%S %z",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/httpd/error_log",
                "log_group_name": "/aws/ec2/instance/httpd-error",
                "log_stream_name": "{instance_id}-error-log",
                "timestamp_format": "%d/%b/%Y:%H:%M:%S %z",
                "timezone": "UTC"
              }
            ]
          }
        }
      }
    }
    EOT

    # Start CloudWatch Agent
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

    # Ensure CloudWatch Agent starts on boot
    sudo systemctl enable amazon-cloudwatch-agent

    # Start and enable Apache to run on boot
    sudo systemctl start httpd
    sudo systemctl enable httpd

    # Create a simple HTML page
    echo "<html>
    <head>
      <title>Fitness App</title>
    </head>
    <body>
      <h1>This is my fitness app1c</h1>
    </body>
    </html>" | sudo tee /var/www/html/index.html

    # Restart Apache to ensure the page loads
    sudo systemctl restart httpd
  EOF

  tags = {
    Name = "private_fitapp1c"
  }
}


#Private SG

resource "aws_security_group" "private_sg" {
  name        = "private access"
  description = "allow access to alb"
  vpc_id      = aws_vpc.fitapp.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "private_sg"
  }

}
resource "aws_security_group_rule" "private_sg_rule" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.alb_sg.id

}

#alb
resource "aws_lb" "fitapp_alb" {
  name               = "fitappalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_instance.id, aws_subnet.public_instance1c.id]

  tags = {
    Name = "fitapp_alb"
  }

}

#alb list=tener
resource "aws_lb_listener" "fitapp_listener" {
  load_balancer_arn = aws_lb.fitapp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fitapp_targetgroup.arn
  }

  tags = {
    Name = "fitapp_listener"
  }

}

#alb target group
resource "aws_lb_target_group" "fitapp_targetgroup" {
  name     = "fitapptargetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.fitapp.id


  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3


  }
  tags = {
    name = "fitapp_targetgroup"
  }

}

#alb target attachment
resource "aws_lb_target_group_attachment" "fitapp_targetgroup_attach" {
  target_group_arn = aws_lb_target_group.fitapp_targetgroup.arn
  target_id        = aws_instance.private_fitapp.id
  port             = 80

}
resource "aws_lb_target_group_attachment" "fitapp_targetgroup_attach1c" {
  target_group_arn = aws_lb_target_group.fitapp_targetgroup.arn
  target_id        = aws_instance.private_fitapp1c.id
  port             = 80

}

#alb SG
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allow traffic to alb"
  vpc_id      = aws_vpc.fitapp.id

  ingress {
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "alb_dns_name" {
  value       = aws_lb.fitapp_alb.dns_name
  description = "shortcut"
}

#rds fitnessdatabase
resource "aws_db_instance" "rds_fitness" {
  allocated_storage      = 100
  engine                 = "mysql"
  engine_version         = "8.0.34"
  instance_class         = "db.t3.micro"
  identifier             = "rdsfitnessapp"
  password               = jsondecode(aws_secretsmanager_secret_version.rds_cred_version.secret_string)["password"]
  username               = jsondecode(aws_secretsmanager_secret_version.rds_cred_version.secret_string)["username"]
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_fitness_sub.name

  tags = {
    Name = "rdsfitnessapp"
  }


}

#rds sub group
resource "aws_db_subnet_group" "rds_fitness_sub" {
  name       = "rds_fitness_sub"
  subnet_ids = [aws_subnet.private_instance2.id, aws_subnet.private_instance2c.id]

  tags = {
    Name = "rds_fitness_sub"
  }

}

#rds sg
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "allow access to fitapp"
  vpc_id      = aws_vpc.fitapp.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_security_group_rule" "rds-sg_rule" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.private_sg.id

}

#s3 through gateway endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.fitapp.id
  service_name      = "com.amazonaws.us-west-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_route.id]

  tags = {
    Name = "s3_gateway"
  }

}




