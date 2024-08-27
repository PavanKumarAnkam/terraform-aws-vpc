# resource "aws_vpc_peering_connection" "peering" {
#   peer_owner_id = var.peer_owner_id
#   peer_vpc_id   = aws_vpc.bar.id
#   vpc_id        = aws_vpc.foo.id
# }

resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_req ?1:0
  vpc_id        = aws_vpc.main.id #requestor
  peer_vpc_id   = var.acceptor_vpc_id == ""? data.aws-vpc.default.id : var.acceptor_vpc_id    #acceptor

  tags = merge(
      var.common_tags,
      var.vpc_peering_tags,
    {
      Name="${local.resource_name}"
    }
  )
} 

resource "aws_route" "public_route" {
  count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
  route_table_id            = aws_route_table.public.id 
  destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
  nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
}

resource "aws_route" "private_route" {
  count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
  route_table_id            = aws_route_table.private.id 
  destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
  nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
}

resource "aws_route" "database_route" {
  count = (var.is_peering_req && var.acceptor_vpc_id == "") ? 1 : 0 #if count = 0 then this resource shouldn't be created
  route_table_id            = aws_route_table.database.id 
  destination_cidr_block    = data.aws_vpc.default.cidr_block # default vpc's cidr
  nat_gateway_id = aws_internet_gateway.gw.id  # target in aws console
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id # we can replace [0] with [count.index]
}