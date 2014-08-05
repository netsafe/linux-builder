```Markdown
Every module must be named as <module_name>.module file in modules.d, so it will be referenced like this further and after

Manadatory functions :

* _init <module_name> - initialize the module file. It is called one time at the VERY first hand. It should return 0 if there's no further calls needed, or 1 otherwise
* _fetch <module_name> - fetches a module's sources from SCM or from an official website. Be sure to use git_fetch and arch_fetch functions in there!
* _extract <module_name> - extracts the module's sources. Use git_extract or arch_extract here!
* _build <module_name> <configure_string> - (pre)configure and build one. Pay attention to BUILD_CC/CXX/CFLAGS/CPPFLAGS/CXXFLAGS/LD/LDFLAGS vars here! For further reference take a look at samples
* _actual <module_name> - returns 1 if the module is actual, 0 if it's not, 2 if it's unsupported
* _getactualdpendency - returns a space-delimited string of dependencies. Be EXTRA careful here! If you need some extra modules here - be sure to supply them!

Русская версия :

Каждый модуль должен быть в файле <имя_модуля>.module, и так к нему будут обращаться впредь

Обязательные функции :

* _init <имя_модуля> - первичная инициализация модуля. Вызывается в САМОМ начале. Должен вернуть 0, если не нужно вызывать еще раз, иначе 1
* _fetch <имя_модуля> - Скачивает исходный код самого модуля с системы контроля версий или с официального сайта. Используйте функции git_fetch и arch_fetch в этом методе!
* _extract <имя_модуля> - Распаковывает исходники модуля. пользуйтесь git_extract или arch_extract в этом методе!
* _build <имя_модуля> <строка_для_configure> - (pre)configure и собственно сборка. Учтите переменные BUILD_CC/CXX/CFLAGS/CPPFLAGS/CXXFLAGS/LD/LDFLAGS в этом методе! Для большей наглядности обязательно посмотрите примеры!
* _actual <имя_модуля> - возвращает 1, если установлена актуальная версия модуля, иначе 0, или 2 если проверка не поддерживается
* _getactualdpendency - возвращает разделенную пробелами строку того, от чего зависит этот модуль. Будьте ПРЕДЕЛЬНО осторожны при реализации данной функции! Если Вам нужно что-то дополнительное - будьте уверены, что Вы предоставили это в качестве модулей!


```