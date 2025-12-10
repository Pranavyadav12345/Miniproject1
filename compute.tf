data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "random_id" "random_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  public_key = file("id_rsa_project_demo.pub")
}

resource "aws_instance" "web_server" {
  count         = var.main_instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet[count.index].id
  key_name      = aws_key_pair.deployer_key.key_name
  #user_data     = templatefile("main-userdata.tpl", { new_hostname = "web-server-${random_id.random_node_id[count.index].dec}" })

  tags = {
    Name = "web-server-${random_id.random_node_id[count.index].dec}"
  }

#   provisioner "local-exec" {
#   # Change the path below to match your Git installation location
#   #interpreter = ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]
  
#   # Your Bash command
#   command     = "printf '\\n${self.public_ip}' >> aws_hosts"
# }

#   provisioner "local-exec" {
#     when    = destroy
#     #interpreter = ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]
#     command = "sed -i '/^[0-9]/d' aws_hosts"
#   }

  vpc_security_group_ids = [aws_security_group.project_sg.id]
}

# locals {
#   # 1. The original Windows path provided (using forward slashes)
#   windows_key_path = var.private_key_path
  
#   # 2. Convert to the WSL path
#   # We search for "C:" and replace it with "/mnt/c"
#   wsl_key_path = replace(local.windows_key_path, "C:/Users/utki_", "~")
# }

# resource "null_resource" "grafana_provisioner" {
  
#   # 1. Dependency: Waits for the instance to be created and the IP to be written.
#   depends_on = [aws_instance.web_server] 
  
#   # 2. Remote-Exec (SSH Wait Loop): This is CRUCIAL. It forces Terraform 
#   #    to wait until the instance is fully booted and the SSH port is open.
#   # provisioner "remote-exec" {
        
#   #   connection {
#   #     type        = "ssh"
#   #     user        = "ubuntu" # Standard user for Ubuntu AMI
#   #     host        = aws_instance.web_server[0].public_ip 
#   #     private_key = var.aws_prv_key_content
#   #     # Note: Ensure the private key content is provided correctly by Jenkins
#   #     timeout     = "5m" # Wait up to 5 minutes
#   #   }

#   #   # Placeholder command to force the connection attempt
#   #   inline = ["echo 'Connection test successful. Instance is ready for Ansible.'"] 
#   # }

#   # 3. Local-Exec (Ansible Call): Runs ONLY after the SSH wait succeeds.
#   provisioner "local-exec" {
#     # 🚨 USE WSL INTERPRETER 🚨
#     #interpreter = ["wsl", "bash", "-c"] 

#     # The Ansible command using the aws_hosts file and your private key
#     command = "ansible-playbook --private-key ${var.aws_prv_key_content} playbooks/grafana.yml"
#   }
#}