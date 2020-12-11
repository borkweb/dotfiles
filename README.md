# dotfiles
My current dotfiles

## tmux configuration

In my terminal, on launch I run the following command to launch with a tmux session called `main` for the first terminal that I open and subsequent terminals will not have tmux running by default.

```
/usr/bin/zsh -c "if ! tmux ls 2>/dev/null | grep -q -E '^main.*attached'; then tmux attach -t main || tmux new -s main; else /usr/bin/zsh; fi"
```
