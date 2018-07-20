#aws ec2 delete-security-group --group-id sg-e1fb8c9a
#Delete your subnets:
readFile=`cat data.txt`
ids=($readFile)
vpcId=${ids[0]}
region=${ids[2]}
natGateId=${ids[13]}

#delete nat gateway
aws ec2 delete-nat-gateway --nat-gateway-id $natGateId

echo "Deleting NAT Gateway.. This may take a few minutes..."

SECONDS=0
LAST_CHECK=0
STATE='deleting'
until [[ $STATE == 'deleted' ]]; do
  INTERVAL=$SECONDS-$LAST_CHECK
  if [[ $INTERVAL -ge $CHECK_FREQUENCY ]]; then
    STATE=$(aws ec2 describe-nat-gateways \
      --nat-gateway-ids $natGateId \
      --query 'NatGateways[*].{State:State}' \
      --output text \
      --region $region)
    LAST_CHECK=$SECONDS
  fi
  SECS=$SECONDS
done

echo "Nat Gateway deleted.. "

#disassociating Eip

eipAllocId=${ids[12]}
aws ec2 release-address --allocation-id $eipAllocId
echo "eip released.."

#deleting all subnets

subId=${ids[4]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[5]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[6]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[7]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[8]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[9]}
aws ec2 delete-subnet --subnet-id $subId

subId=${ids[10]}
aws ec2 delete-subnet --subnet-id $subId

echo "subnets deleted.."

#Delete your custom route table:
routeT1Id=${ids[14]}
aws ec2 delete-route-table --route-table-id $routeT1Id

routeT2Id=${ids[15]}
aws ec2 delete-route-table --route-table-id $routeT2Id

echo "route tables deleted.."

#Detach your Internet gateway from your VPC:

igId=${ids[11]}
aws ec2 detach-internet-gateway --internet-gateway-id $igId --vpc-id $vpcId

#Delete your Internet gateway:
aws ec2 delete-internet-gateway --internet-gateway-id $igId

#Delete your VPC
aws ec2 delete-vpc --vpc-id $vpcId
echo "Vpc deleted succesfully.."

