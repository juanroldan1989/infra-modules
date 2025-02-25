# ------------------------------------------------------------------------
# CREATE SQS QUEUE
# ------------------------------------------------------------------------

locals {
  sqs_tags = {
    Name    = "${var.env}-${var.aws_region}-${var.queue_name}-sqs"
    Service = "SQS"
    Purpose = "Simple Queue Service"
  }
}

resource "aws_sqs_queue" "main" {
  name                      = "${var.env}-${var.aws_region}-${var.queue_name}-sqs"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  fifo_queue                = false
  tags                      = local.sqs_tags
}
