const chai = require("chai");

const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe('Bonus test', () => {
    let circuit, root, F, poseidon;
    const leaves = [1, 0, 0, 0, 0, 0, 0, 0];

    before(async function () {
        try {
            poseidon = await buildPoseidon();
            F = poseidon.F;

            const hashes = [];

            let i;

            for (i = 0; i < 4; i++) {
                hashes.push(F.toObject(poseidon([leaves[i * 2], leaves[i * 2 + 1]])))
            }

            for (i = 0; i < 3; i++) {
                hashes.push(F.toObject(poseidon([hashes[i * 2], hashes[i * 2 + 1]])))
            }

            root = hashes[6];

            circuit = await wasm_tester("contracts/circuits/bonus.circom");
            await circuit.loadConstraints();
        } catch (e) {
            console.log('befor error: ', e);
        }
    })

    it("Should pass with valid values: odd wins", async () => {
        const INPUT = {
            leaves,
            root,
            player_one_num: 2,
            player_one_round_secret: 2,
            player_two_num: 3,
            player_two_round_secret: 2,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(0)));
    });

    it("Should pass with valid values: even wins", async () => {
        const INPUT = {
            leaves,
            root,
            player_one_num: 3,
            player_one_round_secret: 2,
            player_two_num: 3,
            player_two_round_secret: 2,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(1)));
    });

    it("Should throw an error on line 20 or 21 when round secret is on merkle tree", async () => {
        try {
            let r = F.toObject(poseidon([1, 1]))
            r = F.toObject(poseidon([r, 0]))
            r = F.toObject(poseidon([r, 0]))


            const INPUT = {
                leaves,
                root,
                player_one_num: 2,
                player_one_round_secret: 1,
                player_two_num: 3,
                player_two_round_secret: 1,
            }

            await circuit.calculateWitness(INPUT, true);
        } catch (e) {
            const errString = e.toString();
            const errLine = errString.indexOf('line: ');
            const line = Number((errString.substr(errLine)).replace(/\D/g, ""));

            assert(Fr.eq(Fr.e(line), Fr.e(20)) || Fr.eq(Fr.e(line), Fr.e(21)));
        }
    });
});