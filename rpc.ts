import { Connection } from '@_koii/web3.js';
import { getTaskStateInfo } from '@_koii/create-task-cli';

const connection = new Connection("https://testnet.koii.network");

async function getMyTaskInfo(task_id: string): Promise<string> {
    const taskInfo = await getTaskStateInfo(connection, task_id);
    return JSON.stringify(taskInfo);
}

async function main() {
    const args = process.argv.slice(2);
    const command = args[0] as keyof typeof commands;
    const data = args[1];

    const commands: Record<string, (data: string) => Promise<string>> = {
        "task-info": getMyTaskInfo,
    };

    if (!commands[command]) {
        throw new Error(`Unknown command: ${command}`);
    }

    return commands[command](data);
}

main()
    .then((res) => console.log(res))
    .catch((error) => console.error(""));
