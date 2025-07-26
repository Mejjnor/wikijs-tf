resource "aws_vpc" "wiki-js-vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "wiki-js-igw" {
  vpc_id = aws_vpc.wiki-js-vpc.id
}

resource "aws_subnet" "wiki-js-subnets" {
  vpc_id = aws_vpc.wiki-js-vpc.id
  for_each = var.vpc_subnets
  tags = {
    Name = format("wiki-js-%s", each.key)
  }
  cidr_block = each.value[0]
  availability_zone = each.value[1]
  map_public_ip_on_launch = startswith(each.key, "public") ? true : false
}

resource "aws_eip" "wiki-js-nat-ip" {}

resource "aws_nat_gateway" "wiki-js-nat" {
  subnet_id = aws_subnet.wiki-js-subnets["public1"].id
  allocation_id = aws_eip.wiki-js-nat-ip.id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.wiki-js-igw]
}

resource "aws_route" "wiki-js-egress-route" {
  route_table_id = aws_vpc.wiki-js-vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.wiki-js-igw.id
}

resource "aws_route_table" "wiki-js-nat-egress" {
  vpc_id = aws_vpc.wiki-js-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wiki-js-nat.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "wiki-js-nat-egress-ass" {
  subnet_id = aws_subnet.wiki-js-subnets["private"].id
  route_table_id = aws_route_table.wiki-js-nat-egress.id
}
