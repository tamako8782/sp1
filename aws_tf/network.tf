# VPCの作成
resource "aws_vpc" "sprint1_vpc" {
  cidr_block           = "10.0.0.0/21" # ネットワークの範囲を指定
  enable_dns_support   = true          # DNSサポートを有効化
  enable_dns_hostnames = true          # ホスト名解決を有効化
  tags = {
    Name = "reservation-vpc" # リソースの識別用タグ
  }
}

# インターネットゲートウェイの作成

resource "aws_internet_gateway" "sprint1_igw" {
  vpc_id = aws_vpc.sprint1_vpc.id
  tags = {
    Name = "reservation-ig"
  }
}


# パブリックサブネットの作成
resource "aws_subnet" "sprint1_web_sub" {
  vpc_id                  = aws_vpc.sprint1_vpc.id
  cidr_block              = "10.0.0.0/24"     # サブネットの範囲を指定
  availability_zone       = "ap-northeast-1a" # アベイラビリティゾーンを指定
  map_public_ip_on_launch = true              # インスタンスにパブリックIPを割り当て
  tags = {
    Name = "web-subnet-01"
  }
}

resource "aws_subnet" "sprint1_api_sub" {
  vpc_id                  = aws_vpc.sprint1_vpc.id
  cidr_block              = "10.0.1.0/24"     # サブネットの範囲を指定
  availability_zone       = "ap-northeast-1c" # アベイラビリティゾーンを指定
  map_public_ip_on_launch = true              # インスタンスにパブリックIPを割り当て
  tags = {
    Name = "api-subnet-01"
  }
}


# ルートテーブルの作成(web)

resource "aws_route_table" "sprint1_route_table_web" {
  vpc_id = aws_vpc.sprint1_vpc.id
  tags = {
    Name = "web-routetable"
  }
}

# ルートテーブルの作成(api)
resource "aws_route_table" "sprint1_route_table_api" {
  vpc_id = aws_vpc.sprint1_vpc.id
  tags = {
    Name = "api-routetable"
  }
}

# インターネットゲートウェイ向けのルート(web)

resource "aws_route" "sprint1_web_route" {
  route_table_id         = aws_route_table.sprint1_route_table_web.id
  gateway_id             = aws_internet_gateway.sprint1_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# インターネットゲートウェイ向けのルート(api)

resource "aws_route" "sprint1_api_route" {
  route_table_id         = aws_route_table.sprint1_route_table_api.id
  gateway_id             = aws_internet_gateway.sprint1_igw.id
  destination_cidr_block = "0.0.0.0/0"
}


# ルートテーブルとサブネットの関連付け(web)
resource "aws_route_table_association" "sprint1_route_asso_igw_web" {
  route_table_id = aws_route_table.sprint1_route_table_web.id
  subnet_id      = aws_subnet.sprint1_web_sub.id
}

# ルートテーブルとサブネットの関連付け(api)
resource "aws_route_table_association" "sprint1_route_asso_igw_api" {
  route_table_id = aws_route_table.sprint1_route_table_api.id
  subnet_id      = aws_subnet.sprint1_api_sub.id
}

