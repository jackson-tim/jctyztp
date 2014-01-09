# "Junos Config To Your ZTP" Server

 
  
  This example illustrates a hybrid technique for "zero touch provisioning".  It combines Junos features [autoinstallation](http://www.juniper.net/techpubs/en_US/junos12.3/topics/concept/ex-series-configuration-files-autoinstallation.html) or [ZTP](http://www.juniper.net/techpubs/en_US/junos12.3/topics/task/configuration/software-image-and-configuration-automatic-provisioning-confguring.html) with your backend webserver.  The goal of this process is to simplify the DHCP server configuration, and allow for per-device Junos OS and configuration installation.
  
  Junos products that support autoinstallation or ZTP utilize a DHCP and TFTP process to obtain an IP address and initial configuration file (aka bootfile).  Typically the DHCP server is used to map MAC addresses (or something device specific) to a specific configuration file.  The ZTP process goes one step further to use DHCP options to identify a Junos software image.
  
  Some customers are looking for a flexible solution that allows them to do the following:
  
  1. Have a *minimal* DHCP server config that does **not** require changes as devices are added/removed
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

## Kickstart Config for EX (11.4)

These switches seem to ignore the boot-file and request network.conf from the next-server. To actually get a commit with DHCP you need to deactivate autoinstall in the config as well. The [network.conf](network.conf) file here should work for various versions, since some appear to autoinstall with me0 and some with only vlan.0.

## Script Execution

  Once Junos obtains the jctyztp.slax script, the code will perform the following
  
  * (1)  Make an HTTP-GET request to obtain the device's specific Junos configuration file.  The actual mechanics of how that configuration file is produced is specific to your application, not this script.  The return of the HTTP-GET is simply a Junos configuration text file.
  * (2)  The configuraiton **MUST** contain a specific group/apply-macro.  This macro identifies the specific Junos OS package that should be running on the device.  Here is an example.  You do **NOT** add this group to an apply-group configuration; it's just simply being used to store the information that jctyztp.slax needs.
  
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

## SLAX 1.0 Version

Unforatunately Juniper is shipping new equipment (manufactured in Q4 2013) that is running 11.4 (or older) software. This limits
us to SLAX 1.0. I've added a functional SLAX 1.0 script [here](jctyztp-slax10.slax) that should work for the most part.

## Notes

I've modified both versions of the script to change the URL for the config to:

http://ztpserver/juniper/<SERIALNUMBER>/config

I've gone the route of just serving static configs for now to the boxes and not using the Sinatra (or other) web-server included.

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
  
### Starting the Webserver

You start up the webserver from your Linux prompt very simply.  You will need to be root since the server is using port 80.
  
````
root@myserver$ ruby webapp/server.rb
````

If you want to change the HTTP server port to somthing other than 80, then you will need to make the change it two places:  (1) in the server.rb file and (2) throughout the jctyztp.slax file where the http calls are being made.

# SYSLOG

The jctyztp script logs status to syslog. Within the jctyztp.slax script there is a variable called `$SYSLOG` that identifies the syslog facility.severy.  It is presently set to `user.info`.  The example kickstart config includes syslog settings so these messages are displayed on the device console.  

Here is some example output for a simple use-case: OS install is not required:
````
Aug  2 10:53:48  kickstart cscript: jctyztp[5028]: SCRIPT-BEGIN
Aug  2 10:53:48  kickstart cscript: jctyztp[5028]: obtaining device config file
Aug  2 10:53:50  kickstart cscript: jctyztp[5028]: has-ver:13.2X50-D10.2 should-ver:jinstall-ex-2200-13.2X50-D10.2-domestic-signed.tgz
Aug  2 10:53:51  kickstart cscript: jctyztp[5028]: committing configuration
Aug  2 10:54:20  staging_switch cscript: jctyztp[5028]: SCRIPT-END

````

# ERROR-HANDLING

The jctztp script has code to ensure that only one instance of the script is running.  It creates a "lockfile" in /tmp/jctyztp.lock.  If for any reason you run into issues/errors, you can always manually remove the file.

Additional error handling will be added to jctyztp.slax as well.

# DEPENDENCIES

 * Junos device supporting autoinstallation or ZTP feature
 * Ruby 1.9.3 or later
 * RubyGem: sinatra
 * RubyGem: sinatra-contrib
 
# LICENSE
BSD-2, see [LICENSE](LICENSE.md) file
