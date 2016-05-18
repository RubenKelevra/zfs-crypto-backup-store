DEVICE="/dev/sdX"
ROOT_FOLDER="/backupstore"


sudo cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "$DEVICE"
sudo cryptsetup luksOpen "$DEVICE" backup
sudo mkdir -p "$ROOT_FOLDER"
sudo zpool create -f -m "$ROOT_FOLDER" backupstore /dev/mapper/backup
sudo zfs create backupstore/root

sudo zfs set atime=off        backupstore/root
sudo zfs set compression=gzip-9 backupstore/root
sudo zfs set dedup=on           backupstore/root
sudo zfs set redundant_metadata=most backupstore/root

sudo zfs set mountpoint="$ROOT_FOLDER" backupstore

sudo zfs umount /backupstore || true
sudo zfs export backupstore || true
sudo cryptsetup luksClose backup 
sudo eject $DEVICE

echo "done!"
