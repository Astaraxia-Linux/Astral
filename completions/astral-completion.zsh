#compdef astral

# Astral zsh completion

local -a commands opts

commands=(
  '-S:Sync/install package'
  '--Sync:Sync/install package'
  '-C:Compile package without installing'
  '--Compile:Compile package without installing'
  '-SA:Sync from ASURA repository'
  '--Sync-Asura:Sync from ASURA repository'
  '--Upgrade-All:Upgrade all installed packages'
  '-u:Update repository index'
  '--Update:Update repository index'
  '-s:Search for package'
  '--Search:Search for package'
  '-R:Remove package'
  '--Remove:Remove package'
  '-r:Remove package and dependencies'
  '--RemoveDep:Remove package and dependencies'
  '-Cc:Clean source cache'
  '--Clean-Cache:Clean source cache'
  '-U:Self-update astral'
  '--self-update:Self-update astral'
  '--info:Show package information'
  '-I:Show package information'
  '--inspect:Inspect package recipe'
  '--list-installed:List installed packages'
  '-ll:List installed packages'
  'ls:List installed packages'
  '-D:Show package dependencies'
  '--Deps:Show package dependencies'
  '-Dc:Check system dependencies'
  '--DepCheck:Check system dependencies'
  '--config:Show configuration'
  '--rebuild-index:Rebuild files index'
  '--show-env:Show build environment'
  '--hold:Hold package (prevent upgrade)'
  '--unhold:Unhold package'
  '--list-held:List held packages'
  '-v:Verbose output'
  '--verbose:Verbose output'
  '-V:Show version'
  '--version:Show version'
  '-h:Show help'
  '--help:Show help'
)

opts=(
  '--dir:Installation root directory'
  '-f:Force build/reinstall'
  '--force:Force build/reinstall'
  '-n:Dry run'
  '--dry-run:Dry run'
  '-y:Skip confirmation'
  '--yes:Skip confirmation'
  '-q:Quiet mode'
  '--quiet:Quiet mode'
  '--check-version:Check for updates'
  '-p:Pretend mode'
  '--pretend:Pretend mode'
  '--json:JSON output mode'
)

# Main completion
_astral() {
    local -a args
    args=($opts $commands)
    
    _describe 'command' args && return
    
    # If at command position, complete commands
    if (( CURRENT == 1 )); then
        _describe 'command' commands
        return
    fi
    
    # Complete package names for commands that need them
    local cmd="$words[1]"
    local need_pkg=1
    
    case "$cmd" in
        --Upgrade-All|--list-held|--list-installed|-Cc|--Clean-Cache|-Dc|--DepCheck|--config|-v|--verbose|-V|--version|-h|--help)
            need_pkg=0
            ;;
    esac
    
    if [[ $need_pkg -eq 1 ]]; then
        local -a packages
        packages=()
        
        # Add installed packages
        if [[ -d "/var/lib/astral/db" ]]; then
            packages+=$(find /var/lib/astral/db -type f -name version -maxdepth 2 2>/dev/null | \
                sed "s|/var/lib/astral/db/||" | sed 's|/version$||')
        fi
        
        # Add local recipes
        if [[ -d "/usr/src/astral/recipes" ]]; then
            packages+=$(find /usr/src/astral/recipes -type d -maxdepth 2 2>/dev/null | \
                sed 's|/usr/src/astral/recipes/||' | grep '/')
        fi
        
        compadd -a packages
    fi
}

_astral "$@"
