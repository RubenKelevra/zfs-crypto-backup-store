DEVICE="/dev/disk/by-uuid/1234567..."

sudo cryptsetup luksOpen $DEVICE backup
sudo mkdir -p /backupstore/
sudo zpool import backupstore

echo "storage successfully opened, checking integrity..."
sudo zpool scrub backupstore

if [ "$(sudo zpool status -x backupstore)" != "pool 'backupstore' is healthy" ]; then
        echo "Backup-storage is broken, replace it!"
        exit 1
else
        echo "Backup-storage is fine, run a full system-backup..."
fi

sudo zfs set relatime=on        backupstore/root
sudo zfs set compression=gzip-9 backupstore/root
sudo zfs set dedup=on           backupstore/root
sudo zfs set sync=disabled      backupstore/root

sudo rsync -qaAXv --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/*/.cache/*","/home/*/Downloads/*","/home/*/tmp/*","/backupstore","/home/*/.claws-mail/imapcache/*","/var/cache/pacman/pkg/*","/var/log/journal/*"} /* /backupstore/root/
sudo zfs set sync=standard       backupstore/root
sudo sync

echo "Full system-backup done, current snapsnots:"
sudo  zfs list -o space -t snapshot
echo "creating a new snapshot..."
sudo zfs snapshot backupstore/root@$(date --rfc-3339="seconds" | sed -e 's/ /T/' | cut -d '+' -f1)

read -p "halting, if you want to destroy a snapshot, do it now, then press ENTER!"

echo "unmounting and closing luks..."

sudo zfs umount /backupstore || sudo zfs umount -f /backupstore || true
sudo zpool export -f backupstore
sudo cryptsetup luksClose backup 
sudo eject $DEVICE

echo "done!"
