resource "aws_key_pair" "auth_key" {

  key_name   = "${var.project_name}-${var.project_env}"
  public_key = file("git.pub")
  tags = {
    Name = "${var.project_name}-${var.project_env}"
  }
}

resource "aws_security_group" "site-access" {

  name        = "${var.project_name}-${var.project_env}-site-access"
  description = "${var.project_name}-${var.project_env}-site-access"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  tags = {
    Name = "${var.project_name}-${var.project_env}-http-access"
  }

}

resource "aws_security_group" "remote-access" {

  name        = "${var.project_name}-${var.project_env}-remote-access"
  description = "${var.project_name}-${var.project_env}-remote-access"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }



  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  tags = {
    Name = "${var.project_name}-${var.project_env}-remote-access"
  }

}

resource "aws_instance" "frontend" {

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.auth_key.key_name
  user_data              = file("setup.sh")
  vpc_security_group_ids = [aws_security_group.site-access.id, aws_security_group.remote-access.id]

  tags = {
    Name = "${var.project_name}-${var.project_env}-frontend"
  }

  lifecycle {

    create_before_destroy = true
  }
}

resource "aws_eip" "frontend" {
  instance = aws_instance.frontend.id
  domain   = "vpc"
  tags = {
    Name        = "${var.project_name}-${var.project_env}-frontend"
    Project     = var.project_name
    Environment = var.project_env
  }
}





resource "aws_route53_record" "frontend" {

  zone_id = data.aws_route53_zone.public.id
  name    = "${var.hostname}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 60
  records = [aws_eip.frontend.public_ip]
}





