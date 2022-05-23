pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/mux1.circom";

template MerkleTreeNoInclusionProof(n) {
    var numLeaves = 2 ** n;

    // The round secret that can not be in the merkle tree
    signal input secret;

    // All the leaves of the merkle tree
    signal input leaves[numLeaves];

    // The calculated root of the merkle tree
    signal output root;

    component hashes[numLeaves - 1];

    var numFirstHashes = numLeaves / 2;
    var i;

    for (i=0; i < numFirstHashes; i++) {
        // Checks if the secret is in the merkle tree
        assert(secret != leaves[i * 2]);
        assert(secret != leaves[i * 2 + 1]);

        // calculates the hashes of the leaves in pair
        hashes[i] = Poseidon(2);
        hashes[i].inputs[0] <== leaves[i * 2];
        hashes[i].inputs[1] <== leaves[i * 2 + 1];
    }

    var k = 0;
    for (i=numFirstHashes; i < numLeaves - 1; i++) {
        // calculates the hashes based on previous hashes of merkle tree
        hashes[i] = Poseidon(2);
        hashes[i].inputs[0] <== hashes[k * 2].out;
        hashes[i].inputs[1] <== hashes[k * 2 + 1].out;
        k++;
    }

    root <== hashes[numLeaves - 2].out;
}

template OddsAndEvens() {
    // all leaves of the merkle tree
    signal input leaves[8];
    // the merkle tree root on the blockchain
    signal input root;

    // the number that the first player has chosen
    signal input player_one_num;
    // the round secret tha the first player provided
    signal input player_one_round_secret;

    // the number that the second player has chosen
    signal input player_two_num;
    // the round secret tha the second player provided
    signal input player_two_round_secret;

    // the output that represent if even or odd wins => 0 for odd and 1 for even
    signal output is_even;

    // checks if both secret provided are the same (if it is the same round)
    player_one_round_secret === player_two_round_secret;

    component noInclusionProof = MerkleTreeNoInclusionProof(3);

    // passes the secret to check if exists on the merkle tree
    noInclusionProof.secret <== player_one_round_secret;

    for (var i = 0; i < 8; i++) {
        noInclusionProof.leaves[i] <== leaves[i];
    }

    // checks if the root on the blockchain is the same than the calculated
    root === noInclusionProof.root;

    var sum = player_one_num + player_two_num;
    var remainder = sum % 2;

    component isZero = IsZero();

    isZero.in <-- remainder;

    is_even <== isZero.out;
}

component main = OddsAndEvens();