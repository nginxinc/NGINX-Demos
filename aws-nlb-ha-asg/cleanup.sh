cd terraform \
&& terraform init \
&& yes yes | terraform destroy \
&& rm -rf .terraform terraform.* \
&& aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=tag:Name,Values=ngx-plus" --query "Images[].ImageId" --output text) \
&& aws ec2 deregister-image --image-id $(aws ec2 describe-images --filters "Name=tag:Name,Values=ngx-oss" --query "Images[].ImageId" --output text)
