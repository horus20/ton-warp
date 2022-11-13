pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template Sha256Num(nBits) {
    signal input in[nBits];

    component hasher = Sha256(nBits);
    for (var i=0; i<nBits; i++) {
        hasher.in[i] <== in[i];
    }

    component bits2num = Bits2Num(256);
    bits2num.in <== hasher.out;
    for (var i=0; i<256; i++) {
        bits2num.in[i] <== hasher.out[i];
    }

    signal output out <== bits2num.out;
}
