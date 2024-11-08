import { Connection } from '@_koii/web3.js';
import { getTaskStateInfo } from '@_koii/create-task-cli';

const connection = new Connection("https://testnet.koii.network");

async function getTaskInfo(task_id) {
    return JSON.stringify(await getTaskStateInfo(connection, task_id));
}

async function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const data = args[1];

    const commands = {
        "task-info": getTaskInfo,
    };
    return commands[command](data);
}

main()
    .then((res) => console.log(res))
    .catch(error => console.log(""));
