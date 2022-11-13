pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "./sha256Num.circom";

// Helper template that computes hashes of the next tree layer
template TreeLayer(height) {
    var nItems = 1 << height;
    signal input ins[nItems * 2];
    signal output outs[nItems];

    component hash[nItems];

    for(var i = 0; i < nItems; i++) {
        hash[i] = Sha256Num(2);
        hash[i].in[0] <== ins[i * 2];
        hash[i].in[1] <== ins[i * 2 + 1];
        outs[i] <== hash[i].out;
    }
}

// Builds a merkle tree from leaf array
template MerkleTree(levels) {
    signal input leaves[1 << levels];
    signal output root;

    component layers[levels];
    for(var level = levels - 1; level >= 0; level--) {
        layers[level] = TreeLayer(level);
        for(var i = 0; i < (1 << (level + 1)); i++) {
            layers[level].ins[i] <== level == levels - 1 ? leaves[i] : layers[level + 1].outs[i];
        }
    }

    root <== levels > 0 ? layers[0].outs[0] : leaves[0];
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices bits is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template MerkleProof(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices;

    component switcher[levels];
    component hasher[levels];

    component indexBits = Num2Bits(levels);
    indexBits.in <== pathIndices;

    for (var i = 0; i < levels; i++) {
        switcher[i] = Switcher();
        switcher[i].L <== i == 0 ? leaf : hasher[i - 1].out;
        switcher[i].R <== pathElements[i];
        switcher[i].sel <== indexBits.out[i];

        hasher[i] = Sha256Num(2);
        hasher[i].in[0] <== switcher[i].outL;
        hasher[i].in[1] <== switcher[i].outR;
    }

    signal output root <== hasher[levels - 1].out;
}
