
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

#import the newly set bashrc
source "$HOME/.bash_profile"

#install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ||:

#install core programs with brew
brew install node python3 htop 
brew cleanup

brew cask install whatsapp docker firefox flux google-chrome google-drive sublime-text iterm2  transmission vlc 
brew cask cleanup

#sym link to the iterm2 settings
ln -s -f "$dotfiles/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

# Netsoc first
ssh-keygen -f ~/.ssh/id_netsoc -N '' -q
cat ~/.ssh/id_netsoc.pub | ssh cube "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
cat ~/.ssh/id_netsoc.pub | ssh spoon "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"

#Banterbox
ssh-keygen -f ~/.ssh/id_banterbox -N '' -q
cat ~/.ssh/id_banterbox.pub | ssh banterbox-II "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"

read -p "Please Enter the Name of the github repos to clone: `echo $'\n> '`" repo
while [ ! -z $repo ]; do
    git clone "https://github.com/gradecak/$repo" "$HOME/Documents/$repo"
    read -p "Please Enter the Name of the github repos to clone: `echo $'\n> '`" repo
done

echo "Finished"
