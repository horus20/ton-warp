pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/sha256/sha256.circom";

template Keypair() {
    signal input privateKey;

    component hasher = Sha256(1);
    hasher.in[0] <== privateKey;

    signal output publicKey[256] <== hasher.out;
}

template Signature() {
    signal input privateKey;
    signal input commitment;
    signal input merklePath;

    component hasher = Sha256(3);
    hasher.in[0] <== privateKey;
    hasher.in[1] <== commitment;
    hasher.in[2] <== merklePath;

    signal output out[256] <== hasher.out;
}
