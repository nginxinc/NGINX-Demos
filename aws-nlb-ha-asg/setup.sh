cd terraform \
&& yes yes | terraform destroy \
&& rm -rf .terraform \
&& terraform init \
&& cd ../packer \
&& packer build -force ./packer.json \
&& cd ../terraform \
&& yes yes | terraform apply
