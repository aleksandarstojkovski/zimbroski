#!/bin/bash 

######################################################################
# Script Name      : zimbroski                                                                                           
# Description      : Backup and restore zimbra                                                                                                                                                                      
# Author       	   : Aleksandar Stojkovski                                              
# Email            : aleksandar@stojkovski.ch                                          
######################################################################

######################################################################
# functions
######################################################################

################################
# function get_parameters
################################

function get_arguments {

  while [[ $# -gt 0 ]]; do
    case $1 in
      -b)
        ZIMBRA_ACTION_BACKUP="backup"
        ZIMBRA_ACTION="$ZIMBRA_ACTION_BACKUP"
        shift # eat -b
        ZIMBRA_BACKUP_DIR=${1%/} # remove trailing slash
        shift # eat argument of -b
        ;;
      -r)
        ZIMBRA_ACTION_RESTORE="restore"
        ZIMBRA_ACTION="$ZIMBRA_ACTION_RESTORE"
        shift # eat -r
        ZIMBRA_BACKUP_DIR=${1%/} # remove trailing slash
        shift # eat argument of -r
        ;;
      -h)
        dis_usage
        ;;
      *)
        dis_usage "Incorrect parameter!"
        ;;
    esac
  done

  if [[ -n $ZIMBRA_ACTION_BACKUP && -n $ZIMBRA_ACTION_RESTORE ]]; then
    dis_usage "arguments -b and -r cannot be combined"
  fi

  if [[ -z $ZIMBRA_ACTION_BACKUP && -z $ZIMBRA_ACTION_RESTORE ]]; then
    dis_usage "argument -b or -r must be specified"
  fi

}

################################
# function dis_usage
################################

function dis_usage {

    if [[ -n $1 ]]; then
        echo
        echo "Error: $1"
    fi

    echo
    echo "Usage: ./zimbroski.sh [ -b <BACKUP_PATH> ] | [ -r <RESTORE_PATH> ]"
    echo
    echo "      -b backup path, must exist, must be writable by zimbra user"
    echo "      -r restore path, must exist, must be readable by zimbra user"
    echo

    exit 1

}

######################################################################
# MAIN
######################################################################

get_arguments "$@"

################################
# setting variables
################################

ZIMBRA_BACKUP_DIR_DL=$ZIMBRA_BACKUP_DIR/distribution_lists_members
ZIMBRA_BACKUP_DIR_PASSWORDS=$ZIMBRA_BACKUP_DIR/user_passwords
ZIMBRA_BACKUP_DIR_DATA=$ZIMBRA_BACKUP_DIR/user_data
ZIMBRA_BACKUP_DIR_ALIASES=$ZIMBRA_BACKUP_DIR/aliases

################################
# precheck
################################

# check current user is zimbra technical user 
if [[ $(whoami) != "zimbra" ]]; then
    dis_usage "script must be run as zimbra technical user"
fi

# check base dir exist
if [[ ! -d "$ZIMBRA_BACKUP_DIR" ]]; then
    dis_usage "directory \"$ZIMBRA_BACKUP_DIR\" does not exist"
fi

# checks to do if action is backup
if [[ $ZIMBRA_ACTION == "backup" ]]; then

  if [[ ! -w $ZIMBRA_BACKUP_DIR ]]; then
      dis_usage "directory \"$ZIMBRA_BACKUP_DIR\" is not writable"
  fi
  
fi

# checks to do if action is restore
if [[ $ZIMBRA_ACTION == "restore" ]]; then

  if [[ ! -w $ZIMBRA_BACKUP_DIR ]]; then
    dis_usage "directory \"$ZIMBRA_BACKUP_DIR\" is not readable"
  fi

  if [[ ! -d $ZIMBRA_BACKUP_DIR_DL ]] || [[ ! -d $ZIMBRA_BACKUP_DIR_PASSWORDS ]] || [[ ! -d $ZIMBRA_BACKUP_DIR_DATA ]] || [[ ! -d $ZIMBRA_BACKUP_DIR_ALIASES ]]; then
    dis_usage "missing directories in restore path"
  fi

fi

###################################
# backup
###################################

if [[ $ZIMBRA_ACTION = "backup" ]]; then

  echo "INFO - Creating needed directories for backup ..."
  if [[ ! -d $ZIMBRA_BACKUP_DIR_DL ]]; then
      mkdir "$ZIMBRA_BACKUP_DIR_DL"
  fi

  if [[ ! -d $ZIMBRA_BACKUP_DIR_PASSWORDS ]]; then
      mkdir "$ZIMBRA_BACKUP_DIR_PASSWORDS"
  fi

  if [[ ! -d $ZIMBRA_BACKUP_DIR_DATA ]]; then
     mkdir "$ZIMBRA_BACKUP_DIR_DATA"
  fi

  if [[ ! -d $ZIMBRA_BACKUP_DIR_ALIASES ]]; then
    mkdir "$ZIMBRA_BACKUP_DIR_ALIASES"
  fi

  echo "INFO - Exporting domains ..."
  zmprov gad > $ZIMBRA_BACKUP_DIR/domains.txt

  echo "INFO - Exporting admins ..."
  zmprov gaaa > $ZIMBRA_BACKUP_DIR/admins.txt

  echo "INFO - Exporting email addresses ..."
  zmprov -l gaa > $ZIMBRA_BACKUP_DIR/emails.txt

  echo "INFO - Exporting distribution lists ..."
  zmprov gadl > $ZIMBRA_BACKUP_DIR/distribution_lists.txt

  echo "INFO - Exporting distribution lists members ..."
  for dl in $(cat $ZIMBRA_BACKUP_DIR/distribution_lists.txt); do 
      zmprov gdlm $dl > $ZIMBRA_BACKUP_DIR_DL/$dl.txt
      echo "  -> $dl exported"
  done

  echo "INFO - Exporting user passwords ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
      zmprov  -l ga $email userPassword | grep userPassword: | awk '{ print $2}' > $ZIMBRA_BACKUP_DIR_PASSWORDS/$email.shadow
      echo "  -> $email exported"
  done

  echo "INFO - Exporting user names, given names and display names ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
      zmprov ga $email  | grep -i Name: > $ZIMBRA_BACKUP_DIR_DATA/$email.txt
      echo "  -> $email exported"
  done

  echo "INFO - Export aliases ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
      zmprov ga  $email | grep zimbraMailAlias |awk '{print $2}' > $ZIMBRA_BACKUP_DIR_ALIASES/$email.txt
      echo "  -> $email exported"
  done

  echo "INFO - Removing empty aliases ..."
  cd /tmp ; find $ZIMBRA_BACKUP_DIR_ALIASES/ -type f -empty | xargs -n1 rm -v 

  echo "INFO - Exporting mailboxes ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
    zmmailbox -z -m $email getRestURL '/?fmt=tgz' > $ZIMBRA_BACKUP_DIR/$email.tgz
    echo "  -> $email exported"
  done

fi

###################################
# restore
###################################

if [[ $ZIMBRA_ACTION == "restore" ]]; then

  echo "INFO - Restoring domains ..."
  for domain in $(cat $ZIMBRA_BACKUP_DIR/domains.txt); do
    zmprov cd $domain zimbraAuthMech zimbra
    echo "  -> $domain added" 
  done

  echo "INFO - Restoring email accounts and passwords ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
    givenName=$(grep givenName: $ZIMBRA_BACKUP_DIR_DATA/$email.txt | cut -d ":" -f2)
    displayName=$(grep displayName: $ZIMBRA_BACKUP_DIR_DATA/$email.txt | cut -d ":" -f2)
    shadowPass=$(cat $ZIMBRA_BACKUP_DIR_PASSWORDS/$email.shadow)
    tmpPass="changeme"
    zmprov ca "$email" "$tmpPass" cn "$givenName" displayName "$displayName" givenName "$givenName" 
    zmprov ma "$email" userPassword "$shadowPass"
  done

  echo "INFO - Restoring mailboxes ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
    zmmailbox -z -m $email postRestURL "/?fmt=tgz&resolve=skip" $ZIMBRA_BACKUP_DIR/$email.tgz
    echo "  -> $email added"
  done

  echo "INFO - Restoring distribution lists ..."
  for dl in $(cat $ZIMBRA_BACKUP_DIR/distribution_lists.txt); do
    zmprov cdl $dl
    echo "  -> $dl added"
  done

  echo "INFO - Restoring distribution lists members ..."
  for dl in $(cat $ZIMBRA_BACKUP_DIR/distribution_lists.txt); do
    for member in $(grep -v '#' $ZIMBRA_BACKUP_DIR_DL/$dl.txt |grep '@'); do
      zmprov adlm $dl $member
      echo "  -> $member added to list $dl"
    done
  done

  echo "INFO - Restoring aliases ..."
  for email in $(cat $ZIMBRA_BACKUP_DIR/emails.txt); do
    if [[ -f "$ZIMBRA_BACKUP_DIR_ALIASES/$email.txt" ]]; then
      for alias in $(grep '@' $ZIMBRA_BACKUP_DIR_ALIASES/$email.txt); do
        zmprov aaa $email $alias
        echo "  -> $email has alias $alias"
      done
    fi
  done

fi
