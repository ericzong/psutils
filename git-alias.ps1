#v0.0.1

[CmdletBinding()]
param(
)

git config --global alias.als 'config --global --get-regexp alias'
git config --global alias.cg 'config --global'
git config --global alias.ss 'status -s .'
git config --global alias.aa 'add .'
git config --global alias.cm 'commit -m'
git config --global alias.acm 'commit -a -m'
git config --global alias.ps 'push'
git config --global alias.co 'checkout'
git config --global alias.br 'branch'
git config --global alias.last 'log -1 HEAD'
git config --global alias.unstage 'reset HEAD --'
