# resource "aws_vpc_peering_connection" "peering" {
#   peer_owner_id = var.peer_owner_id
#   peer_vpc_id   = aws_vpc.bar.id
#   vpc_id        = aws_vpc.foo.id
# }

# resource "aws_vpc_peering_connection" "peering" {
#   count = var.is_peering_req ?1:0
#   vpc_id        = aws_vpc.main.id #requestor
#   peer_vpc_id   = var.acceptor_vpc_id == ""? data.aws-vpc.default.id : var.acceptor_vpc_id    #acceptor

#   tags = merge(
#       var.common_tags,
#       var.vpc_peering_tags,
#     {
#       Name="${local.resource_name}"
#     }
#   )
# } 

# resource "aws_route" "public_route" {
#   count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
#   route_table_id            = aws_route_table.public.id 
#   destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
#   nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
#   vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
# }

# resource "aws_route" "private_route" {
#   count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
#   route_table_id            = aws_route_table.private.id 
#   destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
#   nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
#   vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
# }

# resource "aws_route" "database_route" {
#   count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
#   route_table_id            = aws_route_table.database.id 
#   destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
#   nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
#   vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
# }


###git
resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_required ? 1 : 0
  vpc_id        = aws_vpc.main.id # requestor VPC
  peer_vpc_id   = var.acceptor_vpc_id == "" ? data.aws_vpc.default.id : var.acceptor_vpc_id
  auto_accept = var.acceptor_vpc_id == "" ? true : false
  tags = merge(
    var.common_tags,
    var.vpc_peering_tags,
    {
        Name = "${local.resource_name}" #expense-dev
    }
  )
}

# count is useful to control when resource is actually required n when not req
resource "aws_route" "public_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "private_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "database_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "default_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
  route_table_id            = data.aws_route_table.main.id # default vpc route table
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}




