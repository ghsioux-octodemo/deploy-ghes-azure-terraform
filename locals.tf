locals {
  nsgrules = {
    ssh = {
      name                   = "SSH"
      priority               = 1001
      protocol               = "Tcp"
      destination_port_range = "22"
    }
    smtp = {
      name                   = "SMTP"
      priority               = 1002
      protocol               = "Tcp"
      destination_port_range = "25"
    }
    http = {
      name                   = "HTTP"
      priority               = 1003
      protocol               = "Tcp"
      destination_port_range = "80"
    }
    ssh_admin = {
      name                   = "SSH_ADMIN"
      priority               = 1004
      protocol               = "Tcp"
      destination_port_range = "122"
    }
    snmp = {
      name                   = "SNMP"
      priority               = 1005
      protocol               = "Udp"
      destination_port_range = "161"
    }
    https = {
      name                   = "HTTPS"
      priority               = 1006
      protocol               = "Tcp"
      destination_port_range = "443"
    }
    http_alt = {
      name                   = "HTTP_ALT"
      priority               = 1007
      protocol               = "Tcp"
      destination_port_range = "8080"
    }
    https_alt = {
      name                   = "HTTPS_ALT"
      priority               = 1008
      protocol               = "Tcp"
      destination_port_range = "8443"
    }
    git = {
      name                   = "GIT"
      priority               = 1009
      protocol               = "Tcp"
      destination_port_range = "9418"
    }
  }
}
