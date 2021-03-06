# Zimbroski - the open-source zimbra backup and restore tool

## Description
Backup and restore zimbra users, passwords mailboxes, distribution lists.
This tool can be used also to migrate Zimbra from one server to another.
Run the script with backup argument '-b' on the source server, copy the backup folder on the target server and run the script with restore option '-r', everything will be configured as before.

## Installation

```
git clone https://github.com/aleksandarstojkovski/zimbroski
```

## Usage

```
Usage: ./zimbroski.sh [ -b <BACKUP_PATH> ] | [ -r <RESTORE_PATH> ]

      -b backup path, must exist, must be writable by zimbra user
      -r restore path, must exist, must be readable by zimbra user
```

### Backup Zimbra

`
./zimbroski.sh -b <BACKUP_PATH>
`

### Restore Zimbra

`
./zimbroski.sh -r <RESTORE_PATH>
`

## Test

The tool has been successfully tested on the following Zimbra versions:

```
8.8.X
8.7.X
8.6.X
8.5.X
```

## Donations

Donate: <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QF3RUSYRD5XBE&source=url">PayPal</a>
