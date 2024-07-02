provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "web_sg" {
  name        = "web_security_group"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_launch_configuration" "terraform-launconfig" {
  image_id = "ami-01ed8ade75d4eee2f"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]
  user_data = filebase64("userdata.sh")
  
  # Autu Scaling Group에서 시작 구성을 사용할 때 필요
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_server_asg" {
  launch_configuration = aws_launch_configuration.terraform-launconfig.name
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns = [aws_lb_target_group.web_tg.arn]
  vpc_zone_identifier = ["subnet-064efc35e0a88941d", "subnet-05fcfe1de5328dfe3"]
        
  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web_lb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = ["subnet-064efc35e0a88941d", "subnet-05fcfe1de5328dfe3"]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "web_tg" {
  name        = "web-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-05e81feee5ed30a92"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
