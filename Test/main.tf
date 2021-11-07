provider "azurerm" {
   version = "2.72.0"
   subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   features {}
}

#Create RG with Module
module "CoalfireModule" {
   source = "./CoalfireModule"
}