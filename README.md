# rancid-mellanox

# What This Is

A module for rancid (https://www.shrubbery.net/rancid/) to add support for Mellanox (now NVIDIA) switches running the Onyx operating system.

The original source of this was JackSlateur/mellanox-rancid, however that was developed for the rancid 2 paradigm.
This version is updated to work with the better framework of rancid 3.

# Installation Requirements

rancid 3.x

# Installation Instructions

- Copy `mlnxlogin` to your rancid bin location (`/usr/local/rancid/bin/` perhaps).
- Modify the path to expect at the start of it if required.
- `chmod +x /usr/local/rancid/bin/mlnxlogin`
- Copy mellanox.pm to your rancid libexec location (`/usr/local/rancid/lib/rancid` or somesuch).
- Modify the path to perl at the start of it if required.
- `chmod +x /usr/local/rancid/libexec/mellanox.pm`
- Edit `rancid.types.conf` (in `/usr/local/rancid/etc` or the like) and add:
```
mellanox;login;mlnxlogin
#mellanox;script;mlnxrancid
mellanox;script;rancid -t mellanox
#mellanox;login;clogin
mellanox;module;mellanox
mellanox;inloop;mellanox::inloop
mellanox;command;mellanox::ShowConfiguration;show running-config expanded
#mellanox;command;mellanox::ShowConfiguration;show running-config
```
- Edit `router.db` to add a device as normal, with type `mellanox`:
```
10.0.0.1;mellanox;up
```
- Edit your `.cloginrc` to setup connection information for the device, with something like:
```
add user routername admin
add password routername {apassword} {}
add method routername ssh
add autoenable routername {0}
add cyphertype routername {aes128-ctr}
```
- Optionally, if you don't want to use `admin`, create another user on the device:
```
conf t
username rancid password apassword
username rancid capability monitor
username rancid full-name "Rancid backups"
no username rancid disable
```

# Note On Secrets

The output of `show running-config` obfusticates most secrets (apart from SNMP v2 community strings, which
never seem to be protected).  Such lines with secrets are commented out, and have asterisks inserted in place of the secret.

The output of `show running-config expanded` exposes some secrets like encrypted user passwords, if
the login user has the `admin` capability, but not if they have `monitor` capability).

Either way, the usual rancid variables (e.g. `FILTER_PWDS` and `NOCOMSTR`) will be honoured,
and if set appropriately will attempt to remove any secrets which are displayed.

Curiously, the line `# boot bootmgr password 7 ********` which appears in the
`show running-config` output disappears entirely with `show running-config expanded`.

# Caveats and Issues

- It doesn't appear to be possible to use key authentication methods for ssh.
- A user with capability `monitor` may be suitable for most things, but in some cases you might want a user with capability `admin`.

# Compatibility

Tested with models:

- HPE SN2410M

Tested with Onyx versions:

- v3.9.2110

# Official Status

Not official.  I would like it to be included in the main rancid distribution ...

