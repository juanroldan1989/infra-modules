# SQS module

- This Terraform module provisions an `Amazon SQS queue` with custom parameters for local or cloud deployments.

- It can be provisioned through:

1. `LocalStack` in a local development environment.
2. `AWS cloud` in a production environment.

## Parameters

The module accepts the following parameters for configuring the SQS queue:

- `queue_name`: (Required) The name of the queue to be created.
- `app_name`: (Required) The application name used for tagging.
- `env`: (Required) The environment (e.g., dev, prod) used for tagging.
- `delay_seconds`: (Optional, default: 0) The time in seconds that the delivery of all messages in the queue will be delayed.
- `max_message_size`: (Optional, default: 2048) The limit on the number of bytes a message can contain before Amazon SQS rejects it.
- `message_retention_seconds`: (Optional, default: 86400) The length of time (in seconds) that Amazon SQS retains a message.
- `receive_wait_time_seconds`: (Optional, default: 10) The time for which a ReceiveMessage call will wait for a message to arrive.
- `fifo_queue`: (Optional, default: false) Whether the queue is FIFO (First In, First Out) or standard.

## Outputs

- Once the queue is created, the following outputs are available:

```bash
queue_arn = "arn:aws:sqs:us-east-1:000000000000:queue-a"
queue_url = "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/queue-a"
```

## Send Message

To send a message to your SQS queue, use the following command:

```bash
aws sqs send-message \
  --endpoint-url http://localhost:4566 \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/queue-a \
  --message-body "Hello from LocalStack" --profile default
```

## Notes

- `Localstack` was chosen for these examples, same commands apply when working with `AWS`.

- The SQS URL (`queue_url`) can be different when deploying to `AWS` instead of LocalStack.

- Make sure to replace the `--endpoint-url` with the appropriate URL for your `production` environment if you're using AWS.

- Ensure your AWS credentials are set up correctly in your environment when using AWS services.

- `infrastructure/environments/prod` showcases infrastructure provisioned via `Localstack` with a working application.
