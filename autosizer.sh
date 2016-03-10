#!/bin/bash -e
# Automatic Image file resizer
# Written by SirLagz
strImgFile=$1
extraSpaceMB=$2

if [[ ! $(whoami) =~ "root" ]]; then
echo ""
echo "**********************************"
echo "*** This should be run as root ***"
echo "**********************************"
echo ""
exit
fi

if [[ -z $1 ]]; then
echo "Usage: ./autosizer.sh <Image File> [<extra space in MB>]"
exit
fi

if [[ -z $2 ]]; then
extraSpaceMB=4
fi

if [[ ! -e $1 || ! $(file $1) =~ "x86" ]]; then
echo "Error : Not an image file, or file doesn't exist"
exit
fi

partinfo=`parted -s -m $1 unit B print`
partnumber=`echo "$partinfo" | grep ext4 | awk -F: ' { print $1 } '`
partstart=`echo "$partinfo" | grep ext4 | awk -F: ' { print substr($2,0,length($2)-1) } '`
loopback=`losetup -f --show -o $partstart $1`
e2fsck -f $loopback
minsize=`resize2fs -P $loopback | awk -F': ' ' { print $2 } '`
blocksize=$(dumpe2fs -h $loopback | grep 'Block size' | awk -F': ' ' { print $2 }')
blocksize=${blocksize// /}

let minsize=$minsize+$extraSpaceMB*1048576/$blocksize
resize2fs -p $loopback $minsize
sleep 1
losetup -d $loopback
let partnewsize=$minsize*$blocksize
let newpartend=$partstart+$partnewsize
part1=`parted -s $1 rm 2`
part2=`parted -s $1 unit B mkpart primary $partstart $newpartend`
endresult=`parted -s -m $1 unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $1
