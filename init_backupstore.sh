DEVICE="/dev/sdx"
ROOT_FOLDER="/backupstore"


sudo cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "$DEVICE"
sudo cryptsetup luksOpen "$DEVICE" backup
sudo mkdir -p "$ROOT_FOLDER"
sudo zpool create -f -o ashift=12 -m "$ROOT_FOLDER" backupstore $DEVICE
sudo zfs create backupstore/root

sudo zfs set relatime=on        backupstore/root
sudo zfs set compression=gzip-9 backupstore/root
sudo zfs set dedup=on           backupstore/root

sudo zfs set mountpoint="$ROOT_FOLDER" backupstore

sudo zfs umount /backupstore || true
sudo zfs umount -f /backupstore || true
sudo cryptsetup luksClose backup 
sudo eject $DEVICE

echo "done!"
