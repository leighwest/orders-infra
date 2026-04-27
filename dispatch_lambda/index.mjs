import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

const client = new SQSClient({ region: process.env.AWS_REGION });

export const handler = async (event) => {
  for (const record of event.Records) {
    const body = JSON.parse(record.body);
    console.log('Processing order:', body);

    await delay(7000);

    const dispatchedMessage = {
      ...body,
      dispatchStatus: 'COMPLETED',
    };

    await client.send(
      new SendMessageCommand({
        QueueUrl: process.env.ORDER_DISPATCHED_QUEUE_URL,
        MessageBody: JSON.stringify(dispatchedMessage),
      }),
    );

    console.log('Published dispatched event for order:', body.orderId);
  }
};
