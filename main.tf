provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "newvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "pub1" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone  = "ap-south-1a"
   map_public_ip_on_launch = true
  tags = {
    Name = "pub1"
  }
}

resource "aws_subnet" "pub2" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone  = "ap-south-1b"
   map_public_ip_on_launch = true
  tags = {
    Name = "pub2"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.newvpc.id
  

  tags = {
    Name = "allow_tls"
  }
  
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  
}
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.newvpc.id

  tags = {
    Name = "mainigw"
  }
}



resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.newvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rtable"
  }
}
resource "aws_route_table_association" "artableass" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.rtable.id
}
resource "aws_route_table_association" "artableass2" {
  subnet_id      = aws_subnet.pub2.id
  route_table_id = aws_route_table.rtable.id
}

resource "aws_lb" "albtest" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets = [
    aws_subnet.pub1.id,
    aws_subnet.pub2.id
  ]
  tags = {
    Environment = "production"
  }
  
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.albtest.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_lb_target_group" "target" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.newvpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "targetass" {
  for_each = {
    ec21 = aws_instance.ec21.id
    ec22 = aws_instance.ec22.id
  }

  target_group_arn = aws_lb_target_group.target.arn
  target_id        = each.value
  port             = 80
}


resource "aws_instance" "ec21" {
  ami           = "ami-019715e0d74f695be"   # Ubuntu (example)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.pub1.id
  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]
  user_data = file("user_data.sh")
  
  tags = {
    Name = "1inst"
  }
  

}
resource "aws_instance" "ec22" {
  ami           = "ami-019715e0d74f695be"   # Ubuntu (example)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.pub2.id
  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]
  user_data = file("user_data2.sh")
   
  tags = {
    Name = "2inst"
  }
}

