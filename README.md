What is this
===

Support for Mellanox (now NVIDIA) switches running the Onyx operating system.

The original source of this was JackSlateur/mellanox-rancid, however that was developed
for the rancid 2 paradigm.  This version is updated to work with the better
framework of rancid 3.

The originals had a specific `mlnxlogin`, however testing seems to show that
the native `clogin` in rancid v3 works just fine, so while `mlnxlogin` is included
for now, it is untested by me and not required.

Installation
---

- Copy mellanox.pm to your rancid libexec location (`/usr/local/rancid/lib/rancid` or somesuch)
- Modify the path to perl at the start of it if required
- `chmod +x /usr/local/rancid/libexec/mellanox.pm`
- Tell rancid how to use it, edit `rancid.types.conf` (in `/usr/local/rancid/etc` or somesuch)
and add:
```
mellanox;login;mlnxlogin
#mellanox;script;mlnxrancid
mellanox;script;rancid -t mellanox
#mellanox;login;clogin
mellanox;module;mellanox
mellanox;inloop;mellanox::inloop
mellanox;command;mellanox::ShowConfiguration;write terminal
```
- Add your device to `.clogin` and to your `router.db` as normal, with type `mellanox`
