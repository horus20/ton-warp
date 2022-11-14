pragma circom 2.0.0;

include "./merkleProof.circom";
include "./keypair.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template Transaction() {
    // const
    var nIns = 2;
    var nOuts = 2;
    var levels = 32;

    signal input root;                   // merkle root
    signal input externalAmount;         // public value of nanotons, usign for deposit/withdraw operations
    signal input externalDataHash;       // external data hash

    // data for transaction inputs
    signal input inputNullifier[nIns];
    signal input inAmount[nIns];                // amount for each input
    signal input inPrivateKey[nIns];            // private key for each input
    signal input inSalt[nIns];                  // salt for each input
    signal input inPathIndices[nIns];           // indices in merkle tree
    signal input inPathElements[nIns][levels];  // path to input elements

    // data for transaction outputs
    signal input outputCommitment[nOuts];
    signal input outAmount[nOuts];
    signal input outPubkey[nOuts];
    signal input outSalt[nOuts];

    component inKeypair[nIns];
    component inSignature[nIns];
    component inCommitmentHasher[nIns];
    component inNullifierHasher[nIns];
    component inTree[nIns];
    component inCheckRoot[nIns];
    var sumIns = 0;

    // check inputs
    for (var index = 0; index < nIns; index++) {
        inKeypair[index] = Keypair();
        inKeypair[index].privateKey <== inPrivateKey[index];

        inCommitmentHasher[index] = Poseidon(3);
        inCommitmentHasher[index].inputs[0] <== inAmount[index];
        inCommitmentHasher[index].inputs[1] <== inKeypair[index].publicKey;
        inCommitmentHasher[index].inputs[2] <== inSalt[index];

        inSignature[index] = Signature();
        inSignature[index].privateKey <== inPrivateKey[index];
        inSignature[index].commitment <== inCommitmentHasher[index].out;
        inSignature[index].merklePath <== inPathIndices[index];

        inNullifierHasher[index] = Poseidon(3);
        inNullifierHasher[index].inputs[0] <== inCommitmentHasher[index].out;
        inNullifierHasher[index].inputs[1] <== inPathIndices[index];
        inNullifierHasher[index].inputs[2] <== inSignature[index].out;

        inNullifierHasher[index].out === inputNullifier[index];

        inTree[index] = MerkleProof(levels);
        inTree[index].leaf <== inCommitmentHasher[index].out;
        inTree[index].pathIndices <== inPathIndices[index];
        for (var i = 0; i < levels; i++) {
            inTree[index].pathElements[i] <== inPathElements[index][i];
        }

        // check merkle proof only if amount is non-zero
        inCheckRoot[index] = ForceEqualIfEnabled();
        inCheckRoot[index].in[0] <== root;
        inCheckRoot[index].in[1] <== inTree[index].root;
        inCheckRoot[index].enabled <== inAmount[index];

        sumIns += inAmount[index];
    }

    // check outputs
    component outCommitmentHasher[nOuts];
    component outAmountCheck[nOuts];
    var sumOuts = 0;

    for (var index = 0; index < nOuts; index++) {
        outCommitmentHasher[index] = Poseidon(3);
        outCommitmentHasher[index].inputs[0] <== outAmount[index];
        outCommitmentHasher[index].inputs[1] <== outPubkey[index];
        outCommitmentHasher[index].inputs[2] <== outSalt[index];
        outCommitmentHasher[index].out === outputCommitment[index];

        // Check that amount fits into 255 bits to prevent overflow
        outAmountCheck[index] = Num2Bits(255);
        outAmountCheck[index].in <== outAmount[index];

        sumOuts += outAmount[index];
    }

    // check that there are no same nullifiers among all inputs
    component sameNullifiers[nIns * (nIns - 1) / 2];
    var index = 0;
    for (var i = 0; i < nIns - 1; i++) {
      for (var j = i + 1; j < nIns; j++) {
          sameNullifiers[index] = IsEqual();
          sameNullifiers[index].in[0] <== inputNullifier[i];
          sameNullifiers[index].in[1] <== inputNullifier[j];
          sameNullifiers[index].out === 0;
          index++;
      }
    }

    // verify amount
    sumIns + externalAmount === sumOuts;

    // constraint to make sure extDataHash cannot be changed
    signal externalDataSquare <== externalDataHash * externalDataHash;
}

component main {public [root, externalAmount, externalDataHash, inputNullifier, outputCommitment]} = Transaction();
