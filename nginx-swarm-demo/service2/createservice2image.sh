source ../scripts/constants.inc
findText='<PREFIX>'
command="s#$findText#$dockerPrefix#"
sed -e $command Dockerfile > Dockerfile_temp
docker build -f Dockerfile_temp -t ${dockerPrefix}service2 .
rm Dockerfile_temp
