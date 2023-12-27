rm -f floppy.img

nasm -f bin -o init_bootloader.com init_bootloader.asm
truncate -s 1474560 init_bootloader.com
mv init_bootloader.com floppy.img

nasm -f bin -o main_bootloader.com main_bootloader.asm
dd if=main_bootloader.com of=floppy.img bs=512 count=2 seek=1 conv=notrunc
rm -f main_bootloader.com

nasm -f bin -o main.com main.asm
dd if=main.com of=floppy.img bs=512 count=2 seek=1212 conv=notrunc
rm -f main.com