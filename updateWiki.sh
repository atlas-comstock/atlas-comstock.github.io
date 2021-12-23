#!/bin/bash
cp  ~/mycode/dev_configs/personal_notes/tiddly_wiki.html /Users/yonghao.hu/mycode/atlas-comstock.github.io/wiki/index.html ; 
cd /Users/yonghao.hu/mycode/atlas-comstock.github.io/ || return; git add -u ; git cmm "new wiki" ; git pull  origin master -r && git push origin master
