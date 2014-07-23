```Markdown
linux-builder
=============
by Alexey A. Vesnin , http://vk.com/netsafe , https://www.facebook.com/tornetsafe
IndieGOGO campaign: https://www.indiegogo.com/projects/internet-privacy-and-acceleration-for-everyone

Linux building script for Tor

Tested on Ubuntu Linux 14.04 amd64 mini.iso

for debian-like systems use this BEFORE the first script run :
```
```Shell
sudo -s
apt-get update
apt-get upgrade
apt-get install gcc gcc-multilib g++ bc m4 flex bison libtool automake make preload
```
```Markdown
Command-line options :
<no options> - full run. Need to be done if it's a first time you're doing it!
mini - minimal assembly, GMP, OpenSSL and Tor
cron - just Tor, with patches

Русская версия:

Скрипт для сборки под Linux, проверен на Ubuntu 14.04 64 бита с образа mini.iso
Если Ваша система базирована на Debian, то ПЕРЕД запуском нужно поставить и обновить следующим образом :
```
```Shell
sudo -s
apt-get update
apt-get upgrade
apt-get install gcc gcc-multilib g++ bc m4 flex bison libtool automake make preload
```
```Markdown
Скрипт имеет аргументы с коммандной строки, один, через пробел :
<без опций> - полная сборка. Это НЕОБХОДИМО сделать в первый раз!
mini - пересборка по минимуму, GMP, OpenSSL и сам Tor
cron - только Tor, с патчами
```
