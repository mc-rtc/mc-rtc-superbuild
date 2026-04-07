```
git clone --recurse-submodules -j8 https://github.com/Noceo200/mc-rtc-superbuild-G1-Manipulation.git
bash mc-rtc-superbuild-G1-Manipulation/utils/bootstrap-linux.sh
git config --global user.name "git username"
git config --global user.email "git mail"
cd mc-rtc-superbuild-G1-Manipulation/
cmake --preset=G1-notests
cmake --build --preset=G1-notests
```
