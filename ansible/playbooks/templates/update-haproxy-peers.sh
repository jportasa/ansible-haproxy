{% raw %}
#!/bin/bash

cp /etc/haproxy/haproxy.cfg.template /etc/haproxy/haproxy.cfg

instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
region=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone/)
region=${region:0:${#region}-1}

asg_name=$(aws ec2 describe-instances --instance-ids $instance_id --region $region | jq '.Reservations[].Instances[].Tags[] | select(.Key=="aws:autoscaling:groupName") | .Value' | xargs)
instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $asg_name --region $region --query "AutoScalingGroups[].Instances[].InstanceId" --output text | xargs )
private_ips=$(aws ec2 describe-instances --instance-ids $instances --region $region --query 'Reservations[].Instances[][InstanceId,NetworkInterfaces[].PrivateIpAddresses[0].PrivateIpAddress]' --output text | xargs -I{} echo -n "{};")
IFS=";" read -a results <<< "$private_ips"

for (( i=0; i<$(( ${#results[@]} / 2 )); i++ )); do
  id=${results[$((i*2))]}
  ip=${results[$((1+i*2))]}
  tabs 8
  echo -e "\tserver ${id} ${ip}:80 maxconn 32 check" >> /etc/haproxy/haproxy.cfg
done

# Check haproxy config is OK
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
if [ $? -eq 0 ]; then
  service haproxy reload
fi
{% endraw %}
