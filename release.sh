swift build -c release -Xswiftc -static-stdlib
sudo cp -f .build/release/MakeBinaries /usr/local/bin/MakeBinaries
sudo cp -f .build/release/MakeBinaries /usr/local/bin/mcb