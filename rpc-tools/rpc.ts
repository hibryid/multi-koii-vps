import { Connection, Keypair, PublicKey } from '@_koii/web3.js';
import { checkIsKPLTask, getTaskStateInfo, Withdraw } from '@_koii/create-task-cli';
import { Keypair as SolanaKeypair, PublicKey as SolanaPublicKey } from '@solana/web3.js';

import {
    checkProgram, establishConnection, establishPayer, ClaimReward
} from '@_koii/create-task-cli/build/koii_task_contract/koii_task_contract';

import {
    establishConnection as KPLEstablishConnection,
    establishPayer as KPLEstablishPayer,
    Withdraw as KPLWithdraw,
    checkProgram as KPLCheckProgram,
    ClaimReward as KPLClaimReward
} from '@_koii/create-task-cli/build/kpl_task_contract/task-program';
import { KPLProgramID } from '@_koii/create-task-cli/build/constant';

import * as fs from "fs";
import * as process from "node:process";

async function getMyTaskInfo(data: string[]): Promise<string> {
    const task_id = data[0];
    const connection = new Connection("https://testnet.koii.network");
    const taskInfo = await getTaskStateInfo(connection, task_id);
    return JSON.stringify(taskInfo);
}

async function claim(data: string[]): Promise<string> {
    try {
        const number = data[0];
        const task_id = data[1];
        let beneficiaryAccount = data[2];
        const connection = await establishConnection();
        await KPLEstablishConnection();

        const walletID = fs.readFileSync(`koii-keys/koii-${number}/wallet/id.json`, 'utf-8');
        const secretKeyID = Uint8Array.from(JSON.parse(walletID));
        const payerWallet = Keypair.fromSecretKey(secretKeyID);
        let claimerWalletPath = `koii-keys/koii-${number}/namespace/staking_wallet.json`;

        const taskStateInfoAddress = new PublicKey(task_id)
        await establishPayer(payerWallet);
        await KPLEstablishPayer(payerWallet as unknown as SolanaKeypair);
        let programId = await checkProgram();
        await KPLCheckProgram();

        console.log('Calling ClaimReward');
        const accountInfo = await connection.getAccountInfo(new PublicKey(taskStateInfoAddress.toBase58()));
        const IsKPLTask = await checkIsKPLTask(accountInfo);
        const taskStateJSON = await getTaskStateInfo(
            connection,
            taskStateInfoAddress.toBase58(),
        );
        const stake_pot_account = new PublicKey(taskStateJSON.stake_pot_account);
        console.log('Stake Pot Account', stake_pot_account.toString());
        if (IsKPLTask) {
            // Create the PublicKey
            const token_type = new PublicKey(taskStateJSON.token_type);
            return JSON.stringify(await KPLClaimReward(
                payerWallet as unknown as SolanaKeypair,
                taskStateInfoAddress as unknown as SolanaPublicKey,
                stake_pot_account as unknown as SolanaPublicKey,
                beneficiaryAccount as unknown as SolanaPublicKey,
                claimerWalletPath,
                token_type.toBase58(),
            ));
        } else {
            return JSON.stringify(await ClaimReward(
                payerWallet,
                taskStateInfoAddress,
                stake_pot_account,
                new PublicKey(beneficiaryAccount),
                claimerWalletPath,
            ));
        }
    } catch (err) {
        return "";
    }
}

async function unstake(data: string[]): Promise<string> {
    try {
        const connection = await establishConnection();
        await KPLEstablishConnection();
        const number = data[0];
        const task_id = data[1];
        const walletID = fs.readFileSync(`koii-keys/koii-${number}/wallet/id.json`, 'utf-8');
        let walletSubmitter = fs.readFileSync(`koii-keys/koii-${number}/namespace/staking_wallet.json`, 'utf-8');
        const secretKeyID = Uint8Array.from(JSON.parse(walletID))
        let secretKeySubmitter = Uint8Array.from(JSON.parse(walletSubmitter))

        const payerWallet = Keypair.fromSecretKey(secretKeyID)
        let submitterKeypair = Keypair.fromSecretKey(secretKeySubmitter)
        const taskStateInfoAddress = new PublicKey(task_id)

        await establishPayer(payerWallet);
        await KPLEstablishPayer(payerWallet as unknown as SolanaKeypair);
        let programId = await checkProgram();
        await KPLCheckProgram();

        // console.log(programId)

        const accountInfo = await connection.getAccountInfo(new PublicKey(taskStateInfoAddress.toBase58()));
        const IsKPLTask = await checkIsKPLTask(accountInfo);
        if (IsKPLTask) {
            let programId = new PublicKey(KPLProgramID);
            let walletSubmitter = fs.readFileSync(`koii-keys/koii-${number}/namespace/staking_wallet_kpl.json`, 'utf-8');
            let secretKeySubmitter = Uint8Array.from(JSON.parse(walletSubmitter))
            let submitterKeypair = Keypair.fromSecretKey(secretKeySubmitter)

            return JSON.stringify(await KPLWithdraw(
                payerWallet as unknown as SolanaKeypair,
                taskStateInfoAddress as unknown as SolanaPublicKey,
                submitterKeypair as unknown as SolanaKeypair,
            ));
        } else {
            return JSON.stringify(await Withdraw(payerWallet, taskStateInfoAddress, submitterKeypair));
        }
    } catch (err) {
        return "";
    }
}


async function main() {
    const args = process.argv.slice(2);
    const command = args[0] as keyof typeof commands;
    const data = args.slice(1);

    const commands: Record<string, (data: string[]) => Promise<string>> = {
        "task-info": getMyTaskInfo,
        "unstake": unstake,
        "claim": claim
    };

    if (!commands[command]) {
        throw new Error(`Unknown command: ${command}`);
    }

    return commands[command](data);
}

process.on('SIGINT', function() {
    console.log("Caught interrupt signal");
    process.exit();
});

main()
    .then((res) => console.log(res))
    .catch((error) => console.log(""));

