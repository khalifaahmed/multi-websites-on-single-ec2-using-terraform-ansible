
# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "${data.aws_region.current_region.name}-terraform-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

# Save file
resource "local_file" "ssh_key" {
  filename        = "${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.key_pair.private_key_pem
  file_permission = "0400"

  provisioner "local-exec" {
    command = "ssh-add -k ${path.module}/${aws_key_pair.key_pair.key_name}.pem"
  }
}

# EC2 Instances
resource "aws_instance" "myec2" {
  ami                         = data.aws_ami.redhat.id
  instance_type               = "t3.medium"       #data.aws_region.current_region.name == "eu-north-1" ? "t3.micro" : "t2.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["public"].id]
  count                       = var.ec2_count
  root_block_device {
    volume_size = 10
  }
  tags = {
    "Name" = "multi-websites"
  }
}

resource "aws_network_interface" "additional_nic" {
  count           = var.extra_nic
  subnet_id       = aws_subnet.public[0].id
  security_groups = ["${aws_security_group.grad_proj_sg["public"].id}"]
}

resource "aws_network_interface_attachment" "additional_nic_assoc" {
  count                = var.extra_nic
  instance_id          = aws_instance.myec2[0].id
  network_interface_id = aws_network_interface.additional_nic[count.index].id
  device_index         = count.index + 1
}

resource "aws_eip" "extra_public_ip" {
  count = var.extra_nic
}

resource "aws_eip_association" "eip_assoc" {
  count                = var.extra_nic
  network_interface_id = aws_network_interface.additional_nic[count.index].id
  allocation_id        = aws_eip.extra_public_ip[count.index].id
}

# resource "null_resource" "sleep_command" {
#   provisioner "local-exec" {
#     command = "sleep 120"
#   }
#   depends_on = [aws_network_interface_attachment.additional_nic_assoc[0], aws_network_interface_attachment.additional_nic_assoc[1]]
# }

resource "null_resource" "httpd_multi_hosts" {
  provisioner "local-exec" {
    command = "export clinic_ip=${aws_network_interface.additional_nic[0].private_ip} clinic_dns=${aws_eip.extra_public_ip[0].public_dns} web2_ip=${aws_network_interface.additional_nic[1].private_ip} web2_dns=${aws_eip.extra_public_ip[1].public_dns} instance_ip=${aws_instance.myec2[0].public_ip}; envsubst '$clinic_ip,$clinic_dns,$web2_ip,$web2_dns,$instance_ip' < ./redhat/httpd-multi-host-vars > ./redhat/httpd-multi-host.yaml ; sleep 120 ; ansible-playbook --inventory ${aws_instance.myec2[0].public_ip}, --user ec2-user ./redhat/httpd-multi-host.yaml"
  }
  depends_on = [aws_network_interface_attachment.additional_nic_assoc[0], aws_network_interface_attachment.additional_nic_assoc[1]]
}

output "instance_dns" {
  value = aws_instance.myec2[0].public_dns
}

output "clinic_dns" {
  value = aws_eip.extra_public_ip[0].public_dns
}

output "web2_dns" {
  value = aws_eip.extra_public_ip[1].public_dns
}
