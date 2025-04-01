# Get latest AMI ID for Amazon Linux2 OS

#data "aws_ami" "nat_instance" {
#  most_recent = true
#  owners      = ["amazon"]
#  filter {
#    name   = "name"
#    values = ["amzn-ami-vpc-nat-*"]
#  }
#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#}

#output "redhat_nat_instance_id_in_this_region" {
#  value = data.aws_ami.nat_instance.image_id
#}


data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["RHEL-9.2.0_HVM-*-GP2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

output "redhat_ami_id_in_this_region" {
  value = data.aws_ami.redhat.image_id
}
