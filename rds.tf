resource "aws_security_group" "wiki-rds-sg" {
  vpc_id = aws_vpc.wiki-js-vpc.id
  name = "wiki-rds-sg"
}

resource "aws_db_subnet_group" "wiki-rds-subnets" {
  name = "wiki-rds-subnets"
  subnet_ids = [aws_subnet.wiki-js-subnets["isolated1"].id, 
                aws_subnet.wiki-js-subnets["isolated2"].id]
}

# resource "aws_db_parameter_group" "wiki-js-dbpg" {
#   name = "wikijs-dbpg"
#   family = "postgres14"

#   parameter {
#     name = "rds.force_ssl"
#     value = 1
#     apply_method = "immediate"
#   }
# }

resource "aws_db_instance" "wiki-rds" {
  allocated_storage = 10
  db_name = "wikijs"
  engine = "postgres"
  engine_version = "14.12"
  # parameter_group_name = aws_db_parameter_group.wiki-js-dbpg.name
  instance_class = "db.t3.micro"
  manage_master_user_password = true
  username = "postgres"
  multi_az = false
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.wiki-rds-subnets.name
  vpc_security_group_ids = [aws_security_group.wiki-rds-sg.id]
}

