# "Junos Config To Your ZTP" Server

 
  
  This example illustrates a hybrid technique for "zero touch provisioning".  It combines Junos features [autoinstallation](http://www.juniper.net/techpubs/en_US/junos12.3/topics/concept/ex-series-configuration-files-autoinstallation.html) or [ZTP](http://www.juniper.net/techpubs/en_US/junos12.3/topics/task/configuration/software-image-and-configuration-automatic-provisioning-confguring.html) with your backend webserver.  The goal of this process is to simplify the DHCP server configuration, and allow for per-device Junos OS and configuration installation.
  
  Junos products that support autoinstallation or ZTP utilize a DHCP and TFTP process to obtain an IP address and initial configuration file (aka bootfile).  Typically the DHCP server is used to map MAC addresses (or something device specific) to a specific configuration file.  The ZTP process goes one step further to use DHCP options to identify a Junos software image.
  
  Some customers are looking for a flexible solution that allows them to do the following:
  
  1. Have a *minimal* DHCP server config that does require changes as devices are added/removed
  2. Have the Junos device obtain its specific configuration from an HTTP-GET process (dynamic)
  3. Have the Junos device obtain its OS from an HTTP-GET process that is based on the configuration
  
# AUTOMATION WORKFLOW

  This section outlines the automation workflow from "factory reset".  There are two basic phases.  
  
## Kickstart Config

The first phase we'll call the "kickstart".  Its purpose is to obtain a generic config file that triggers a script.  
  
  1. Junos initiates a DHCP request and obtains an IP-address
  2. DHCP server also returns: (a) TFTP server, (b) bootfile name of *kickstart* Junos configuration
  3. Junos will TFTP-GET the kickstart config and commit it. The config includes an event-trigger  
  4. The event-trigger will HTTP-GET a script, [jctyztp.slax](jctyztp.slax).  The script will perform next step of the process


The kickstart config must contain the Junos event-trigger.  An example kickstart for an EX switch is shown [here](ex-kickstart.conf).  An exaple of just the event trigger config snippet is shown [here](jctyztp-event.conf).

## Script Execution

  Once Junos obtains the jctyztp.slax script, the code will perform the following
  
  * (1)  Make an HTTP-GET request to obtain the device's specific Junos configuration file.  The actual mechanics of how that configuration file is produced is specific to your application, not this script.  The return of the HTTP-GET is simply a Junos configuration text file.
  * (2)  The configuraiton **MUST** contain a specific group/apply-macro.  This macro identifies the specific Junos OS package that should be running on the device.  Here is an example:
  
````
   groups {
       jctyztp {
           apply-macro conf {
               package jinstall-ex-2200-13.2X50-D10.2-domestic-signed.tgz;
           }
       }
   }
````

  * (3)  If the device is not running that version of code, then it will HTTP-GET the OS package, install it, and then reboot the box
  * (-)  If the box reboots, then the kickstart config/event-trigger is still active when the device activates.  The event-trigger will run the jctztp.slax script again, but now the OS version is correct
  * (4)  The device's specific configuration is committed
  * (5)  Process is complete

# DevTest Web Server

This example contains a Sinatra based webserver application.  It's included to provide a mock-up and dev-test environment for the jctyztp.slax script.  The webserver provides the following URL ("routes"):

````
HTTP-GET /juniper/script/<script-filename.slax>
````
  Used to return the jctyztp.slax file to the Junos device.  The kickstart config event-trigger invokes the jctyztp.slax program by the `op url` command. See [here](jctyztp-event.conf) for the example.

````
HTTP-GET /juniper/config.cgi
````
  Used to simulate your backed that will return a Junos configuration text file.  The idea here is that the
  webserver backend will be able to take the HTTP-request fields (like source IP-address) to determine which
  configuration to build/return.  The sample app just returns a fixed file.

````
HTTP-GET /juniper/os/<package-filename.tgz>
````
  Used by the jctyztp script to "file copy" the Junos OS image onto the device
  

# DEPENDENCIES

 * Junos device supporting autoinstallation or ZTP feature
 * Ruby 1.9.3 or later
 * RubyGem: sinatra
 * RubyGem: sinatra-contrib
 
# LICENSE
BSD-2, see [LICENSE](LICENSE.md) file
