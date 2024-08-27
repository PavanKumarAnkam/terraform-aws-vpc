# resource "aws_vpc_peering_connection" "peering" {
#   peer_owner_id = var.peer_owner_id
#   peer_vpc_id   = aws_vpc.bar.id
#   vpc_id        = aws_vpc.foo.id
# }

resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_req ?1:0
  vpc_id        = aws_vpc.main.id #requestor
  peer_vpc_id   = var.acceptor_vpc_id == ""? data.aws-vpc.default.id : var.acceptor_vpc_id    #acceptor
} 