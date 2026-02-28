# Astral fish shell completion
# Install: copy to ~/.config/fish/completions/astral.fish

complete -c astral -s S -l Sync -d 'Sync/install package' -f -a '(astral_complete_packages)'
complete -c astral -s C -l Compile -d 'Compile package without installing' -f -a '(astral_complete_packages)'
complete -c astral -s SA -l Sync-Asura -d 'Sync from ASURA repository' -f -a '(astral_complete_packages)'
complete -c astral -l Upgrade-All -d 'Upgrade all installed packages'
complete -c astral -s u -l Update -d 'Update repository index' -a 'aoharu asura'
complete -c astral -s s -l Search -d 'Search for package' -f -a '(astral_complete_packages)'
complete -c astral -s R -l Remove -d 'Remove package' -f -a '(astral_complete_packages)'
complete -c astral -s r -l RemoveDep -d 'Remove package and dependencies' -f -a '(astral_complete_packages)'
complete -c astral -s Cc -l Clean-Cache -d 'Clean source cache'
complete -c astral -s U -l self-update -d 'Self-update astral' -a 'main cutting-edge bleeding-edge'
complete -c astral -l info -d 'Show package information' -s I -f -a '(astral_complete_packages)'
complete -c astral -l inspect -d 'Inspect package recipe' -s Ins -f -a '(astral_complete_packages)'
complete -c astral -l list-installed -d 'List installed packages' -s ll
complete -c astral -s D -l Deps -d 'Show package dependencies' -f -a '(astral_complete_packages)'
complete -c astral -s Dc -l DepCheck -d 'Check system dependencies'
complete -c astral -l config -d 'Show configuration'
complete -c astral -l rebuild-index -d 'Rebuild files index' -s RI
complete -c astral -l show-env -d 'Show build environment' -s SE
complete -c astral -l hold -d 'Hold package (prevent upgrade)' -f -a '(astral_complete_installed)'
complete -c astral -l unhold -d 'Unhold package' -f -a '(astral_complete_held)'
complete -c astral -l list-held -d 'List held packages'

# Options
complete -c astral -s f -l force -d 'Force build/reinstall'
complete -c astral -s n -l dry-run -d 'Dry run'
complete -c astral -s y -l yes -d 'Skip confirmation'
complete -c astral -s q -l quiet -d 'Quiet mode'
complete -c astral -l check-version -d 'Check for updates'
complete -c astral -s p -l pretend -d 'Pretend mode'
complete -c astral -l json -d 'JSON output mode'
complete -c astral -s v -l verbose -d 'Verbose output'
complete -c astral -s V -l version -d 'Show version'
complete -c astral -s h -l help -d 'Show help'
complete -c astral -l dir -d 'Installation root directory' -r

# Helper functions
function astral_complete_packages
    # Installed packages
    if test -d /var/lib/astral/db
        find /var/lib/astral/db -type f -name version -maxdepth 2 2>/dev/null | sed 's|/var/lib/astral/db/||' | sed 's|/version$||'
    end
    # Local recipes
    if test -d /usr/src/astral/recipes
        find /usr/src/astral/recipes -type d -maxdepth 2 2>/dev/null | sed 's|/usr/src/astral/recipes/||' | grep '/'
    end
    # Remote index
    for idx in /var/lib/astral/db/index_aoharu /var/lib/astral/db/index_asura
        if test -f $idx
            grep -v '^#' $idx | grep '|' | awk -F'|' '{gsub(/ /,"",$1); print $1}'
        end
    end
end

function astral_complete_installed
    if test -d /var/lib/astral/db
        find /var/lib/astral/db -type f -name version -maxdepth 2 2>/dev/null | sed 's|/var/lib/astral/db/||' | sed 's|/version$||'
    end
end

function astral_complete_held
    if test -f /var/lib/astral/holds
        cat /var/lib/astral/holds
    end
end
