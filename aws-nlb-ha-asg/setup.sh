cd packer \
&& packer build -force packer.json \
&& sleep 90 && cd ../terraform \
&& terraform init \
&& yes yes | terraform destroy \
&& yes yes | terraform apply
