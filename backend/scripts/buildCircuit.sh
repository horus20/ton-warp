#!/bin/bash -e
POWERS_OF_TAU=15 # circuit will support max 2^POWERS_OF_TAU constraints
mkdir -p build/circuits
if [ ! -f build/circuits/ptau$POWERS_OF_TAU ]; then
  echo "Downloading powers of tau file"
  curl -L https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_$POWERS_OF_TAU.ptau --create-dirs -o build/circuits/ptau$POWERS_OF_TAU
fi
circom circuits/transaction.circom --r1cs --wasm --sym -o build/circuits/
npx snarkjs groth16 setup build/circuits/transaction.r1cs build/circuits/ptau$POWERS_OF_TAU build/circuits/tmp_transaction.zkey
echo "qwe" | npx snarkjs zkey contribute build/circuits/tmp_transaction.zkey build/circuits/transaction.zkey
npx snarkjs zkey export verificationkey build/circuits/transaction.zkey build/circuits/transaction_verification_key.json
#npx snarkjs zkey export solidityverifier build/circuits/transaction.zkey build/circuits/Verifier.sol
#sed -i.bak "s/contract Verifier/contract Verifier${1}/g" build/circuits/Verifier.sol
#zkutil setup -c build/circuits/transaction.r1cs -p build/circuits/transaction.params
#zkutil generate-verifier -p build/circuits/transaction.params -v build/circuits/Verifier.sol
npx snarkjs r1cs info build/circuits/transaction.r1cs
