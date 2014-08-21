 2751  cd .config/awesome
 2752  git clone git://scm.solitudo.net/delightful.git
 2753  cd delightful
 2754  ls
 2755  cd delightful
 2756  cd ../..
 2757  ls
 2758  mv delightful delightful_git
 2759  ln delightful_git delightful
 2760  ln -s delightful_git delightful
 2761  ll
 2762  rm rc.lua~
 2763  rm rc.lua.orig
 2764  ll
 2765  cd delightful
 2766  git submodule init; git submodule update
 2767  cd ..
 2768  rm delightful
 2769  ln -s delightful_git/delightful delightful
 2770  ll
 2771  ln -s delightful_git/submodules/vicious
 2772  cd freedesktop
 2773  git status
 2774  cd ..
 2775  rm -rf freedesktop
 2776  ln -s delightful_git/submodules/awesome-freedesktop/freedesktop
 2777  ll
 2778  ln -s delightful_git/submodules/imap/lua/imap.lua/imap.lua
 2779  ln -s delightful_git/submodules/weatherlib/src/weatherlib.lua
 2780  ln -s delightful_git/submodules/metar/src/metar.lua
 2781  ln -s delightful_git/calendar2.lua
 2782  apt-get install gnome-icon-theme
 2783  sudo apt-get install gnome-icon-theme
 2784* lynx http://solitudo.net/software/awesome/delightful/README/
 2785  sudo apt-get install sensors-applet
 2786  sudo  install liblua5.1-socket2 liblua5.1-sec1
 2787  sudo apt-get install liblua5.1-socket2 liblua5.1-sec1
 2788  sudo apt-get install liblua5.2-socket2 liblua5.2-sec1
 2789  sudo aptitude
 2790  history
 2791  history | tail 100 | xclipboard
 2792  history | tail -n 100 | xclipboard
 2793  sudo apt-get install xclip
