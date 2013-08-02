# OVERVIEW

  "Junos Config To Your ZTP" server  
  
  This example illustrates a hybrid technique for "zero touch provisioning".  It combines Junos features [autoinstallation](http://www.juniper.net/techpubs/en_US/junos12.3/topics/concept/ex-series-configuration-files-autoinstallation.html) or [ZTP](http://www.juniper.net/techpubs/en_US/junos12.3/topics/task/configuration/software-image-and-configuration-automatic-provisioning-confguring.html) with your backend webserver.  The goal of this process is to simplify the DHCP server configuration, and allow for per-device Junos OS and configuration installation.
  
  Junos products that support autoinstallation or ZTP utilize a DHCP and TFTP process to obtain an IP address and initial configuration file (aka bootfile).  Typically the DHCP server is used to map MAC addresses (or something device specific) to a specific configuration file.  The ZTP process goes one step further to use DHCP options to identify a Junos software image.
  
  Some customers are looking for a flexible solution that allows them to do the following:
  
  1. Have a *minimal* DHCP server config that does require changes as devices are added/removed
  2. Have the Junos device obtain its specific configuration from an HTTP-GET process (dynamic)
  3. Have the Junos device obtain its OS from an HTTP-GET process that is based on the configuration
  
  
# LICENSE
BSD-2, see [LICENSE](LICENSE.md) file
