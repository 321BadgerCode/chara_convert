mkdir ./tmp/
mv ./*.png ./tmp/
for i in ./tmp/*.png; do perl chara.pl $i; done
