``` Markdown
The whole API of mkinstall.sh, documented in code, here are some shotrcuts :
# Usage: get_dependents <module_name> - it will return all the modules that are directly dependent on this very module
# Usage: git_fetch <module_name> <git_scm_url>
# Usage: arch_fetch <module_name> <archive_url> <archive_file_name>
# Usage: git_extract <module_name>
# Usage: arch_extract <module_name> <archive_file_name> [</path/to/exact/extract/location>] [strip level=1]
# Usage: get_dependency_list <module_name> - it will return a string of modules needed to be built to compile your module
# Usage: build_module_recursive <module_name> <previous_dependency_list> - second argument is for avoiding a deadlock inside a recursive loop
# Usage: build_available <module_name> - it will build all the modules that have satisfied dependencies installed. It echoes the process info and status, so avoid it's usage in a functions that are returning values
# Usage remove_from_list <list_name> <token>
# Usage: add_to_list <list_name> <token> - add a token to list avoiding duplicates
# Usage: get_dependents_recursive <module_name> - return all the modules that are hierarchically depend on this one
```