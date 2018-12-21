# Zimbroski - the open-source zimbra backup and restore tool

## Description
Backup and restore zimbra users, passwords mailboxes, distribution lists.
This tool can be used also to migrate Zimbra from one server to another.
Run the script with backup argument '-b' on the source server, copy the backup folder on the target server and run the script with restore option '-r', everything will be configured as before.

## Backup

`
./zimbroski.sh -b <BACKUP_PATH>
`
## Restore

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
