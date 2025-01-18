resource "aws_instance" "web" {
  ami = "ami-08f52b2e87cebadd9"
  instance_type = "t2.micro"
  subnet_id = aws_route_table_association.sprint1_route_asso_igw_web.subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = aws_key_pair.key_pair.key_name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git nginx
    systemctl enable nginx
    systemctl start nginx
    git clone https://github.com/tamako8782/sprint1.git
    rm -rf /usr/share/nginx/html/*
    mv sprint1/web/src/* /usr/share/nginx/html/
    cd /usr/share/nginx/html/
    sed -i 's|const apiIp = "APIIPADDRESS"|const apiIp = "${aws_instance.api.public_ip}"|' /usr/share/nginx/html/index.js
    systemctl restart nginx
    EOF

    user_data_replace_on_change = true
  
  tags = {
    Name = "web-server-01"
  }
}

resource "aws_instance" "api" {
  ami = "ami-08f52b2e87cebadd9"
  instance_type = "t2.micro"
  subnet_id = aws_route_table_association.sprint1_route_asso_igw_api.subnet_id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name = aws_key_pair.key_pair.key_name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git
    git clone https://github.com/tamako8782/sprint1.git
     ./sprint1/api/api_for_linux_amd 
  EOF

  user_data_replace_on_change = true
  tags = {
    Name = "api-server-01"
  }
}

resource "aws_security_group" "web" {
  name = "web-sg"
  vpc_id = aws_vpc.sprint1_vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8888
    to_port = 8888
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "api" {
  name = "api-sg"
  vpc_id = aws_vpc.sprint1_vpc.id
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# https://qiita.com/instant_baby/items/7a70d644c54efa273179 このサイト見て後で続きからやる
# ファイル名のもととなる変数を定義
variable "key_name" {
  type = string
  default = "yama-key-2025"
}

# ローカルに保存するファイル名を定義
locals {
  public_key_file  = "./.key_pair/${var.key_name}.id_rsa.pub"
  private_key_file = "./.key_pair/${var.key_name}.id_rsa"
}

# 秘密鍵を生成
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 秘密鍵をローカルに保存

resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

# 公開鍵をローカルに保存
resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file}"
  }
}

# 公開鍵をAWSに保存
resource "aws_key_pair" "key_pair" {
  key_name = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh
}

# インスタンスのパブリックIPアドレスを出力
output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "api_public_ip" {
  value = aws_instance.api.public_ip
}

