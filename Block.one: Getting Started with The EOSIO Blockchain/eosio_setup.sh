#!/bin/bash

echo "🔄 Updating package lists..."
sudo apt update -y

echo "⬇️ Downloading EOSIO binary..."
curl -LO https://github.com/eosio/eos/releases/download/v2.1.0/eosio_2.1.0-1-ubuntu-20.04_amd64.deb

echo "💾 Installing EOSIO..."
sudo apt install -y ./eosio_2.1.0-1-ubuntu-20.04_amd64.deb

echo "✅ Verifying installation..."
nodeos --version
cleos version client
keosd -v

echo "🚀 Starting nodeos in background..."
nodeos -e -p eosio --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin --contracts-console >> nodeos.log 2>&1 &

sleep 5
echo "📡 nodeos is running. Showing logs..."
tail -n 10 nodeos.log

echo "💼 Creating wallet..."
cleos wallet create --name my_wallet --file my_wallet_password

echo "🔑 Viewing wallet password..."
cat my_wallet_password

echo "🔓 Unlocking wallet..."
wallet_password=$(cat my_wallet_password)
cleos wallet open --name my_wallet
cleos wallet unlock --name my_wallet --password $wallet_password

echo "🔐 Importing EOSIO system private key..."
cleos wallet import --name my_wallet --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

echo "⬇️ Downloading EOSIO CDT..."
curl -LO https://github.com/eosio/eosio.cdt/releases/download/v1.8.1/eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb

echo "💾 Installing EOSIO CDT..."
sudo apt install -y ./eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb

echo "✅ Verifying CDT installation..."
eosio-cpp --version

echo "🧪 Unlocking wallet again to ensure access..."
cleos wallet open --name my_wallet
cleos wallet unlock --name my_wallet --password $wallet_password

echo "🔐 Creating new keypair..."
cleos create key --file my_keypair1
cat my_keypair1

# Extract private key from file
user_private_key=$(grep "Private key:" my_keypair1 | cut -d ' ' -f 3)
user_public_key=$(grep "Public key:" my_keypair1 | cut -d ' ' -f 3)

echo "🔐 Importing user private key..."
cleos wallet import --name my_wallet --private-key $user_private_key

echo "👤 Creating EOSIO account named 'bob' with the new public key..."
cleos create account eosio bob $user_public_key

echo "✅ EOSIO setup and account creation complete!"
