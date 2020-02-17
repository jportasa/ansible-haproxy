{% raw %}
#!/bin/bash

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

region="eu-west-1"
auto_scaling_group="Appserver_ASG"

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.cur
cp  /etc/haproxy/haproxy.cfg.template /etc/haproxy/haproxy.cfg

    var=0
    for i in `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${auto_scaling_group} | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`
    do
        var=$((var+1))
        ip=$(aws ec2 describe-instances --instance-ids $i | grep -i PrivateIpAddress | awk '{ print $2 }' | head -1 | cut -d"," -f1 |tr -d '"')

        if valid_ip $ip
        then
            status=0;
            echo "ip valida";
        else
            cp /etc/haproxy/haproxy.cfg.cur /etc/haproxy/haproxy.cfg
            exit 1;
        fi
        tabs 8
        echo -e "\tserver server${var} ${ip}:80 maxconn 32 check" >> /etc/haproxy/haproxy.cfg

    done;
service haproxy reload

{% endraw %}