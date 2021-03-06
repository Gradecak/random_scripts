#install xcode command line tools
xcode-select --install

#pull dotfiles
dotfiles="$HOME/Documents/dotfiles"
if [ ! -d $dotfiles ]; then
    git clone "https://github.com/Gradecak/dotfiles" $dotfiles
fi

#create soft symlink to the appropriate locations for the dotfiles
ln -s -f "$dotfiles/.bash_profile" "$HOME/.bash_profile"
ln -s -f "$dotfiles/.gitconfig" "$HOME/.gitconfig"
ln -s -f "$dotfiles/config" "$HOME/.ssh/config"
ln -s -f "$dotfiles/.vimrc" "$HOME/.vimrc"
ln -s -f "$dotfiles/.emacs" "$HOME/.emacs"

#setup Vundle plugin manager for vim
git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"


#import the newly set bashrc
source "$HOME/.bash_profile"

#install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ||:

# brew tap railwaycat/emacsmacport
brew tap d12frosted/emacs-plus
#install core programs with brew
brew install emacs-plus --with-natural-title-bar
# brew install node python3 htop emacs-mac
brew cleanup

#install gui programs with brew cask
brew cask install docker firefox flux google-chrome google-drive iterm2 transmission vlc
brew cask cleanup

#sym link to the iterm2 settings
ln -s -f "$dotfiles/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

# Netsoc
ssh-keygen -f ~/.ssh/id_netsoc -N '' -q
cat ~/.ssh/id_netsoc.pub | ssh cube "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
cat ~/.ssh/id_netsoc.pub | ssh spoon "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"

#Clone
read -p "Please Enter the Name of the github repos to clone: `echo $'\n> '`" repo
while [ ! -z $repo ]; do
    git clone "https://github.com/gradecak/$repo" "$HOME/Documents/$repo"
    read -p "Please Enter the Name of the github repos to clone: `echo $'\n> '`" repo
done

echo "Finished"
echo "REMEMBER TO RUN :PluginInstall WHEN STARTING VIM"
