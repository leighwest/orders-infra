import {
  CloudFrontKeyValueStoreClient,
  GetKeyCommand,
} from '@aws-sdk/client-cloudfront-keyvaluestore';
import '@aws-sdk/signature-v4a';

const KVS_ARN =
  'arn:aws:cloudfront::519852452516:key-value-store/76a634ea-b9b1-4aa3-90d7-5fdcecee3c0a';
const client = new CloudFrontKeyValueStoreClient({});

const CLOSED_HTML = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Cupcake Shop — We're Closed</title>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body {
        background: #fdf0e8;
        height: 100vh;
        display: flex;
        justify-content: center;
        align-items: center;
        overflow: hidden;
      }
      img {
        max-width: 80%;
        max-height: 80vh;
        object-fit: contain;
        border-radius: 24px;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
      }
    </style>
  </head>
  <body>
    <img src="/closed.webp" alt="The cupcake shop is closed. We open again at 7am." />
  </body>
</html>`;

export const handler = async (event) => {
  const request = event.Records[0].cf.request;

  if (request.uri === '/closed.webp') {
    return request;
  }

  try {
    const response = await client.send(
      new GetKeyCommand({
        KvsARN: KVS_ARN,
        Key: 'ec2_state',
      }),
    );

    if (response.Value === 'down') {
      return {
        status: '200',
        statusDescription: 'OK',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'text/html' }],
          'cache-control': [{ key: 'Cache-Control', value: 'no-store' }],
        },
        body: CLOSED_HTML,
      };
    }
  } catch (err) {
    console.error('KVS read failed:', err);
  }

  return request;
};
