resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
        Name = local.resource_name
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.igw_tags,
    {
      Name=local.resource_name
    }
  )
}

## basic template - public subnet
# resource "aws_subnet" "main" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "Main"
#   }
# }

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_cidr_tags,
    {
      Name="${local.resource_name}-${local.az_names[count.index]}"
    }
  )
}

## Private Subnet
resource "aws_subnet" "private" { # first name is public[0], second name is public[1]
  count = length(var.private_subnet_cidrs)
  availability_zone = local.az_names[count.index]
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_cidr_tags,
    {
        Name = "${local.resource_name}-private-${local.az_names[count.index]}"
    }
  )
}

## Database Subnet
resource "aws_subnet" "database" { # first name is public[0], second name is public[1]
  count = length(var.database_subnet_cidrs)
  availability_zone = local.az_names[count.index]
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]

  tags = merge(
    var.common_tags,
    var.database_subnet_cidr_tags,
    {
        Name = "${local.resource_name}-database-${local.az_names[count.index]}"
    }
  )
}

resource "aws_db_subnet_group" "default" {
  name       = "${local.resource_name}"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.common_tags,
    var.database_subnet_group_tags,
    {
        Name = "${local.resource_name}"
    }
  )
}

# resource "aws_eip" "lb" {
#   instance = aws_instance.web.id
#   domain   = "vpc"
# }

resource "aws_eip" "elastic" {
  domain   = "vpc"
}

# resource "aws_nat_gateway" "example" {
#   allocation_id = aws_eip.example.id
#   subnet_id     = aws_subnet.example.id

#   tags = {
#     Name = "gw NAT"
#   }

#   # To ensure proper ordering, it is recommended to add an explicit dependency
#   # on the Internet Gateway for the VPC.
#   depends_on = [aws_internet_gateway.example]
# }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.public[0].id # public[0] refers to subnet "us-east-1a", public[1] = us-east-1b

  tags = merge(
      var.common_tags,
      var.nat_gateway_tags,
  {
      Name="${local.resource_name}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# resource "aws_route_table" "example" {
#   vpc_id = aws_vpc.example.id

#   route {
#     cidr_block = "10.0.1.0/24"
#     gateway_id = aws_internet_gateway.example.id
#   }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#   }

#   tags = {
#     Name = "example"
#   }
# }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # route {      # this block is for route we will add later , now we'll create route tables only
  #   cidr_block = "10.0.1.0/24"
  #   gateway_id = aws_internet_gateway.gw.id
  # }
  tags = merge(
      var.common_tags,
      var.public_route_table_tags,
    {
      Name="${local.resource_name}-public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
      var.common_tags,
      var.private_route_table_tags, 
    {
      Name="${local.resource_name}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
      var.common_tags,
      var.database_route_table_tags,
    {
      Name="${local.resource_name}-database"
    }
  )
}


### aws route ###
# resource "aws_route" "r" {
#   route_table_id            = aws_route_table.testing.id
#   destination_cidr_block    = "10.0.1.0/22"
#   vpc_peering_connection_id = "pcx-45ff3dc1"
# }

resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"  # destination in aws console
  nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
}
resource "aws_route" "private_route_nat" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"  # destination in aws console
  nat_gateway_id = aws_nat_gateway.nat.id  # target in aws console
}
resource "aws_route" "database_route_nat" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"  # destination in aws console
  nat_gateway_id = aws_nat_gateway.nat.id  # target in aws console
}

# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.foo.id
#   route_table_id = aws_route_table.bar.id
# }
# resource "aws_route_table_association" "b" {
#   gateway_id     = aws_internet_gateway.foo.id
#   route_table_id = aws_route_table.bar.id
# }

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)  # here * refers to all(2) subnets and we use count for that
    subnet_id      = element(aws_subnet.public[*].id,count.index) # aws_subnet.database[*].id gives--> list && element(list, index)gives particular value at index
    route_table_id = aws_route_table.public.id
 }

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)  # here * refers to all(2) subnets and we use count for that
    subnet_id      = element(aws_subnet.private[*].id,count.index) # aws_subnet.database[*].id gives--> list && element(list, index)gives particular value at index
    route_table_id = aws_route_table.private.id
 }

resource "aws_route_table_association" "database" {
    count = length(var.private_subnet_cidrs)   # here * refers to all(2) subnets and we use count for that
    subnet_id      =element(aws_subnet.database[*].id,count.index)  # aws_subnet.database[*].id gives--> list && element(list, index)gives particular value at index
    route_table_id = aws_route_table.database.id
 }

