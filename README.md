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
target=fullcycle - full run. Need to be done if it's a first time you're doing it!
target=mini - minimal assembly, GMP, OpenSSL and Tor
target=cron - just Tor, with patches
trace=1 - just run trace
module=<module name> - just build exactly the module specified
moduletarget=<module name> - build the module specified along with all pre-requisites

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
target=fullcycle сборка. Это НЕОБХОДИМО сделать в первый раз!
target=mini - пересборка по минимуму, GMP, OpenSSL и сам Tor
target=cron - только Tor, с патчами
trace=1 - протрассировать без сборки
module=<module name> - собрать только указанный модуль
moduletarget=<module name> - собрать все зависимости для модуля и сам модуль


```
