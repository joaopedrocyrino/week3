pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
// include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

// Grand Mastermind
// 5 shapes and 5 colors => 4 holes
template MastermindVariation() {
    // Public inputs
    // Each pub gues is an array containing the shape and the color
    // for each hole
    signal input pubGuessA[2];
    signal input pubGuessB[2];
    signal input pubGuessC[2];
    signal input pubGuessD[2];
    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnA[2];
    signal input privSolnB[2];
    signal input privSolnC[2];
    signal input privSolnD[2];
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[4][2] = [pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4][2] =  [privSolnA, privSolnB, privSolnC, privSolnD];
    var j = 0;
    var k = 0;

    component lessThan[28];
    component equalGuess[12];
    component equalSoln[12];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 5.
    for (j=0; j<4; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j + 4] = LessThan(4);
        lessThan[j + 8] = LessThan(4);
        lessThan[j + 12] = LessThan(4);

        lessThan[j].in[0] <== guess[j][0];
        lessThan[j + 4].in[0] <== guess[j][1];
        lessThan[j + 8].in[0] <== soln[j][0];
        lessThan[j + 12].in[0] <== soln[j][1];

        lessThan[j].in[1] <== 5;
        lessThan[j + 4].in[1] <== 5;
        lessThan[j + 8].in[1] <== 5;
        lessThan[j + 12].in[1] <== 5;

        lessThan[j].out === 1;
        lessThan[j + 4].out === 1;
        lessThan[j + 8].out === 1;
        lessThan[j + 12].out === 1;

        for (k=j+1; k<4; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx + 6] = IsEqual();

            // Checks if shape is equal
            equalGuess[equalIdx].in[0] <== guess[j][0];
            equalGuess[equalIdx].in[1] <== guess[k][0];

            // Checks if color is equal
            equalGuess[equalIdx + 6].in[0] <== guess[j][1];
            equalGuess[equalIdx + 6].in[1] <== guess[k][1];

            // Cecks if the shape and the color are equal
            lessThan[equalIdx + 16] = LessThan(2);
            lessThan[equalIdx + 16].in[0] <==  equalGuess[equalIdx].out + equalGuess[equalIdx + 6].out;
            lessThan[equalIdx + 16].in[1] <== 2;

            lessThan[equalIdx + 16].out === 1;

            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx + 6] = IsEqual();

            // Checks if shape is equal
            equalSoln[equalIdx].in[0] <== soln[j][0];
            equalSoln[equalIdx].in[1] <== soln[k][0];

            // Checks if color is equal
            equalSoln[equalIdx + 6].in[0] <== soln[j][1];
            equalSoln[equalIdx + 6].in[1] <== soln[k][1];

            // Cecks if the shape and the color are equal
            lessThan[equalIdx + 22] = LessThan(2);
            lessThan[equalIdx + 22].in[0] <==  equalSoln[equalIdx].out + equalSoln[equalIdx + 6].out;
            lessThan[equalIdx + 22].in[1] <== 2;

            lessThan[equalIdx + 22].out === 1;

            equalIdx += 1;
        }
    }

    // Count hit & blow
    var hit = 0;
    var blow = 0;
    component equalHB[48];

    for (j=0; j<4; j++) {
        for (k=0; k<4; k++) {
            equalHB[4*j+k] = IsEqual();
            equalHB[4*j+k+16] = IsEqual();
            equalHB[4*j+k+32] = IsEqual();

            equalHB[4*j+k].in[0] <== soln[j][0];
            equalHB[4*j+k].in[1] <== guess[k][0];

            equalHB[4*j+k+16].in[0] <== soln[j][1];
            equalHB[4*j+k+16].in[1] <== guess[k][1];

            equalHB[4*j+k+32].in[0] <== equalHB[4*j+k].out + equalHB[4*j+k+16].out;
            equalHB[4*j+k+32].in[1] <== 2;

            blow += equalHB[4*j+k+32].out;
            if (j == k) {
                hit += equalHB[4*j+k+32].out;
                blow -= equalHB[4*j+k+32].out;
            }
        }
    }

    // Create a constraint around the number of hit
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // Create a constraint around the number of blow
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(9);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA[0];
    poseidon.inputs[2] <== privSolnA[1];
    poseidon.inputs[3] <== privSolnB[0];
    poseidon.inputs[4] <== privSolnB[1];
    poseidon.inputs[5] <== privSolnC[0];
    poseidon.inputs[6] <== privSolnC[1];
    poseidon.inputs[7] <== privSolnD[0];
    poseidon.inputs[8] <== privSolnD[1];

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
}

component main {public [pubGuessA, pubGuessB, pubGuessC, pubGuessD, pubNumHit, pubNumBlow, pubSolnHash]} = MastermindVariation();