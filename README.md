# CIS Security Benchmark Kickstarts
----
The kickstart files in this repository will give you a system which meets almost all of the scored standards from the [CIS Security Benchmarks](http://benchmarks.cisecurity.org/).  The non-scored checks are excluded and I've also excluded adjustments that don't make sense for most environments (see comments in the kickstart for details).

### Disclaimers

* The kickstart files are Apache 2 Licensed
* I'm not affilated with the Center For Internet Security in any way
* These kickstarts aren't approved by the Center For Internet Security
* These kickstarts might not make your system any more secure than it was before you started
* These kickstarts may cause your server to leave the rack and chase cars

### Requirements & Caveats

The kickstarts are currently set up for **KVM-based environments.**  If that's not accurate for your server environment, look for this string in the kickstart:

    --driveorder=vda

Change `vda` to reflect whatever is accurate for your environment.  For example, you may want to change this to `xvda` for Xen VM's or `sda` for physical servers with SATA drives.

I'd recommend starting with a **minimum disk size of 20GB** for these kickstarts.  Adjust the `logvol` lines to smaller sizes if your disk happens to be smaller.

#### Enjoy!
*-- Major Hayden*