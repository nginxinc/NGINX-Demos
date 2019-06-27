variable "machine_type" {
  description = "The machine type of the AWS instance"
  default     = "t2.micro"
}

variable "key_name" {
  description = "The key name used to ssh into your AWS instance"
  default     = ""
}
