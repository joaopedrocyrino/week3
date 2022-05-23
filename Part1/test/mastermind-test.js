const chai = require("chai");

const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe('Grand Mastermind test', () => {
    let circuit, pubSolnHash, F;
    const soln = {
        privSalt: 6787687544627,
        privSolnA: [0, 2],
        privSolnB: [0, 1],
        privSolnC: [4, 4],
        privSolnD: [3, 2]
    }
    const guess = {
        pubGuessA: [0, 2],
        pubGuessB: [0, 0],
        pubGuessC: [4, 4],
        pubGuessD: [0, 1],
        pubNumHit: 2,
        pubNumBlow: 1
    }

    before(async function () {
        const poseidon = await buildPoseidon();
        F = poseidon.F;

        pubSolnHash = F.toObject(poseidon([
            soln.privSalt,
            soln.privSolnA[0],
            soln.privSolnA[1],
            soln.privSolnB[0],
            soln.privSolnB[1],
            soln.privSolnC[0],
            soln.privSolnC[1],
            soln.privSolnD[0],
            soln.privSolnD[1]
        ]))

        guess.pubSolnHash = pubSolnHash;

        circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();
    })

    it("Should pass with valid values", async () => {
        const INPUT = {
            ...guess,
            ...soln
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(pubSolnHash)));
    });

    it("Should throw an error on line 139 when pubNumHit is incorrect", async () => {
        try {
            const INPUT = {
                ...guess,
                ...soln,
                pubNumHit: 1
            }

            await circuit.calculateWitness(INPUT, true);
        } catch (e) {
            const errString = e.toString();
            const errLine = errString.indexOf('line: ');
            const line = Number((errString.substr(errLine)).replace(/\D/g, ""));

            assert(Fr.eq(Fr.e(line), Fr.e(139)));
        }
    });

    it("Should throw an error on line 145 when pubNumBlow is incorrect", async () => {
        try {
            const INPUT = {
                ...guess,
                ...soln,
                pubNumBlow: 3,
            }

            await circuit.calculateWitness(INPUT, true);
        } catch (e) {
            const errString = e.toString();
            const errLine = errString.indexOf('line: ');
            const line = Number((errString.substr(errLine)).replace(/\D/g, ""));

            assert(Fr.eq(Fr.e(line), Fr.e(145)));
        }
    });

    it("Should throw an error on line 160 when pubSolnHash is incorrect", async () => {
        try {
            const INPUT = {
                ...guess,
                ...soln,
                pubSolnHash: 10980980982019,
            }

            await circuit.calculateWitness(INPUT, true);
        } catch (e) {
            const errString = e.toString();
            const errLine = errString.indexOf('line: ');
            const line = Number((errString.substr(errLine)).replace(/\D/g, ""));

            assert(Fr.eq(Fr.e(line), Fr.e(160)));
        }
    });
});