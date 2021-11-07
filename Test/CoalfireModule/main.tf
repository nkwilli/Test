#Create RG----------------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "project-rg" {
  name     = "Project-RG2"
  location = "eastus"
}

#Create Networking---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg1" {
  name                = var.nsg1_name
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name

    security_rule {
    name                       = "allow-ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg2" {
  name                = var.nsg2_name
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name

  security_rule {
    name                       = "allow-lb"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "40.76.70.194"
    destination_address_prefix = "*"
  }
}
#}
resource "azurerm_virtual_network" "vnet1" {
  name                = "virtualNetwork1"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sub1" {
  name                 = "sub1"
  resource_group_name  = azurerm_resource_group.project-rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet_network_security_group_association" "sub1-associate" {
  subnet_id                 = azurerm_subnet.sub1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}
resource "azurerm_subnet" "sub2" {
  name                 = "sub2"
  resource_group_name  = azurerm_resource_group.project-rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet" "sub3" {
  name                 = "sub3"
  resource_group_name  = azurerm_resource_group.project-rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet_network_security_group_association" "sub3-associate" {
  subnet_id                 = azurerm_subnet.sub3.id
  network_security_group_id = azurerm_network_security_group.nsg2.id
}
resource "azurerm_subnet" "sub4" {
  name                 = "sub4"
  resource_group_name  = azurerm_resource_group.project-rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
  

#Create availability set--------------------------------------------------------------------------------------------------------------------------
resource "azurerm_availability_set" "vmset" {
  name                = "VM-Set"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name
}

#Create VM1-----------------------------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "interface" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "VM-1"
  resource_group_name = azurerm_resource_group.project-rg.name
  location            = azurerm_resource_group.project-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.interface.id,
  ]
  availability_set_id   = azurerm_availability_set.vmset.id

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/e0399481/vm1.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8"
    version   = "latest"
  }
}

#Create Disk and Attach to VM1-------------------------------------------------------------------------------------------------------------------
resource "azurerm_managed_disk" "vm1-disk" {
  name                 = "VM1-Disk"
  location             = azurerm_resource_group.project-rg.location
  resource_group_name  = azurerm_resource_group.project-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm1-disk-attachment" {
  managed_disk_id    = azurerm_managed_disk.vm1-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm1.id
  lun                = "10"
  caching            = "ReadWrite"
}

#Create VM2------------------------------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "interface2" {
  name                = "vm2-nic"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "VM-2"
  resource_group_name = azurerm_resource_group.project-rg.name
  location            = azurerm_resource_group.project-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.interface2.id,
  ]
  availability_set_id   = azurerm_availability_set.vmset.id
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/e0399481/vm2.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8"
    version   = "latest"
  }
}

#Create Disk and Attach to VM2------------------------------------------------------------------------------------------------------------------------
resource "azurerm_managed_disk" "vm2-disk" {
  name                 = "VM2-Disk"
  location             = azurerm_resource_group.project-rg.location
  resource_group_name  = azurerm_resource_group.project-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm2-disk-attachment" {
  managed_disk_id    = azurerm_managed_disk.vm2-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm2.id
  lun                = "10"
  caching            = "ReadWrite"
}

#Create VM3 with Apache------------------------------------------------------------------------------------------------------------------------------
#resource "azurerm_public_ip" "apache_terraform_pip"{
 # name = "Apache-Pip"
 # location = azurerm_resource_group.project-rg.location
 # resource_group_name  = azurerm_resource_group.project-rg.name
  #allocation_method = "Dynamic"
 # domain_name_label = "apache-host"
#}

resource "azurerm_network_interface" "interface3" {
  name                = "vm3-nic"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub3.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.apache_terraform_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm3" {
  name                = "Apache-VM"
  resource_group_name = azurerm_resource_group.project-rg.name
  location            = azurerm_resource_group.project-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.interface3.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/e0399481/vm3.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8"
    version   = "latest"
  }
}
#Install Apache on VM3-----------------------------------------------------------------------------------------------
#provisioner "remote-exec" {
 # inline = [
    #"sudo yum -y install httpd && sudo systemct1 start httpd",
    #"sudo mv index.html /var/www/html/"
 # ]
  #connection {
    #type = "ssh"
  #  host = azurerm_public_ip.apache_terraform_pip.fqdn
   # user = "adminuser"
    #private_key = file("C:/Users/e0399481/vm3.txt")
 # }
#}

#Create Disk and Attach to VM3--------------------------------------------------------------------------------------------------------------------------------
resource "azurerm_managed_disk" "vm3-disk" {
  name                 = "Apache-Disk"
  location             = azurerm_resource_group.project-rg.location
  resource_group_name  = azurerm_resource_group.project-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm3-disk-attachment" {
  managed_disk_id    = azurerm_managed_disk.vm3-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm3.id
  lun                = "10"
  caching            = "ReadWrite"
}

#Create Load Balancer with NAT RUles-------------------------------------------------------------------------------
resource "azurerm_public_ip" "lb-ip" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "apache-lb" {
  name                = "ApacheLoadBalancer"
  location            = azurerm_resource_group.project-rg.location
  resource_group_name = azurerm_resource_group.project-rg.name


  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb-ip.id
  }
}
resource "azurerm_lb_backend_address_pool" "backend-pool" {
  loadbalancer_id = azurerm_lb.apache-lb.id
  name            = "BackEndAddressPool"
}
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = azurerm_network_interface.interface3.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
}
resource "azurerm_lb_nat_rule" "lb-nat" {
  resource_group_name            = azurerm_resource_group.project-rg.name
  loadbalancer_id                = azurerm_lb.apache-lb.id
  name                           = "HttpAccess"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}



#Azure Storage Account with Network Rules------------------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "storage1" {
  name                     = "coalfirestorage123"
  resource_group_name      = azurerm_resource_group.project-rg.name
  location                 = azurerm_resource_group.project-rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

}

resource "azurerm_storage_account_network_rules" "Network1" {
  resource_group_name  = azurerm_resource_group.project-rg.name
  storage_account_name = azurerm_storage_account.storage1.name

  default_action             = "Allow"
  virtual_network_subnet_ids = [azurerm_subnet.sub1.id, azurerm_subnet.sub2.id, azurerm_subnet.sub3.id, azurerm_subnet.sub4.id]
}