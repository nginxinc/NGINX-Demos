cd terraform \
&& terraform init \
&& cd ../packer \
&& packer build -force ./packer.json \
&& cd ../terraform \
&& yes yes | terraform destroy \
&& yes yes | terraform apply
