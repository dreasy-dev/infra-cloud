# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${local.name}-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["195.7.117.146/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Application Load Balancer
resource "aws_lb" "nextcloud" {
  name               = "${local.name}-alb"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  load_balancer_type = "application"

  tags = local.tags
}

# Target Group for Nextcloud
resource "aws_lb_target_group" "nextcloud" {
  name        = "${local.name}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = local.tags
}

# Listener for ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud.arn
  }
}

# Add the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "nextcloud_instance" {
  target_group_arn = aws_lb_target_group.nextcloud.arn
  target_id        = aws_instance.nextcloud.id
  port             = 80
}
