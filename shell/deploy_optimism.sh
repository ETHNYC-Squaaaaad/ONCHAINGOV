# must be ran from project home directory ex. sh shell/deploy_local.sh
source .env
forge script ./src/scripts/Deploy.s.sol:Deploy --fork-url https://kovan.optimism.io --private-key b90103bab0ebef3dbbc450cc6ef79f36a2ac123d05ed7b55dbd0952939a28e78 --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvvv