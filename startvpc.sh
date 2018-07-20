echo "enter vpc name"
read name
echo "enter cidr block IP:"
read cidr
echo "enter cidr block number"
read block
echo "enter vpc region"
read region

#creating VPC

aws_response=$(aws ec2 create-vpc --cidr-block $cidr --region "$region")
vpcId=$(echo -e "$aws_response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')
aws ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="$name"
echo "vpc created with id " $vpcId "and name " $name

#block=/20
var=0
cidrblock="10.0."$var".0"$block
echo $cidrblock

#creating subnets in zone1
echo "creating subnets in zone1"

aws_subnet1=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}a)
subnetId1Zone1=$(echo "$aws_subnet1" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId1Zone1

#naming the subnet
aws ec2 create-tags --resources $subnetId1Zone1 --tags Key=Name,Value=${name}sub1Z1

#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

aws_subnet2=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}a)
subnetId2Zone1=$(echo "$aws_subnet2" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId2Zone1

#naming the subnet
aws ec2 create-tags --resources $subnetId2Zone1 --tags Key=Name,Value=${name}sub2Z1

#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

aws_subnet3=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}a)
subnetId3Zone1=$(echo "$aws_subnet3" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId3Zone1

#naming the subnet
aws ec2 create-tags --resources $subnetId3Zone1 --tags Key=Name,Value=${name}sub3Z1


#creating subnets in zone2
echo "creating subnets in zone2"

#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

aws_subnet1=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}b)
subnetId1Zone2=$(echo "$aws_subnet1" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId1Zone2

#naming the subnet
aws ec2 create-tags --resources $subnetId1Zone2 --tags Key=Name,Value=${name}sub1Z2

#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

aws_subnet2=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}b)
subnetId2Zone2=$(echo "$aws_subnet2" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId2Zone2

#naming the subnet
aws ec2 create-tags --resources $subnetId2Zone2 --tags Key=Name,Value=${name}sub2Z2


#creating subnets in zone3
#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

echo "creating subnetsin zone 3"
aws_subnet1=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}c)
subnetId1Zone3=$(echo "$aws_subnet1" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId1Zone3

#naming the subnet
aws ec2 create-tags --resources $subnetId1Zone3 --tags Key=Name,Value=${name}sub1Z3

#Calculating new CIDR block
var=`expr $var + 16`
cidrblock="10.0."$var".0"$block
echo $cidrblock

aws_subnet2=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidrblock --availability-zone ${region}c)
subnetId2Zone3=$(echo "$aws_subnet2" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $subnetId2Zone3

#naming the subnet
aws ec2 create-tags --resources $subnetId2Zone3 --tags Key=Name,Value=${name}sub2Z3
echo "subnet created"


#creating Internet Gateways
echo "Creating Internet Gateways.."

aws_ig=$(aws ec2 create-internet-gateway)
igId=$(echo "$aws_ig" | /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo $igId
aws ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $igId --region $region
aws ec2 create-tags --resources $igId --tags Key=Name,Value=${name}ig

#get elastic IP for NAT gateway

eipAllocId=$(aws ec2 allocate-address --domain vpc --query '{AllocationId:AllocationId}' --output text --region $region)

#aws ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="${name}a1"

# Creating NAT Gateway

natGateId=$(aws ec2 create-nat-gateway \
  --subnet-id $subnetId1Zone1 \
  --allocation-id $eipAllocId \
  --query 'NatGateway.{NatGatewayId:NatGatewayId}' \
  --output text \
  --region $region)
echo "Launching NAT Gateway.. This may take a few minutes..."

SECONDS=0
LAST_CHECK=0
STATE='PENDING'
until [[ $STATE == 'AVAILABLE' ]]; do
  INTERVAL=$SECONDS-$LAST_CHECK
  if [[ $INTERVAL -ge $CHECK_FREQUENCY ]]; then
    STATE=$(aws ec2 describe-nat-gateways \
      --nat-gateway-ids $natGateId \
      --query 'NatGateways[*].{State:State}' \
      --output text \
      --region $region)
    STATE=$(echo $STATE | tr '[:lower:]' '[:upper:]')
    LAST_CHECK=$SECONDS
  fi

  SECS=$SECONDS
Done

aws ec2 create-tags --resources $natGateId --tags Key=Name,Value=${name}NatG --region $region

echo "NAT Gateway is now available.."

#creating route tables

aws_routeT1=$(aws ec2 create-route-table --vpc-id $vpcId)
routeT1Id=$(echo "$aws_routeT1" | /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo $routeT1Id

#naming the route table
aws ec2 create-tags --resources $routeT1Id --tags Key=Name,Value=${name}PubRt1

aws_routeT2=$(aws ec2 create-route-table --vpc-id $vpcId)
routeT2Id=$(echo "$aws_routeT2" | /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo $routeT2Id

#naming the route table
aws ec2 create-tags --resources $routeT2Id --tags Key=Name,Value=${name}PriRt2 


#public route table which has internet gateway present

aws ec2 create-route --route-table-id $routeT1Id --destination-cidr-block 0.0.0.0/0 --gateway-id $igId

#private route table which has nat gateway

aws ec2 create-route --route-table-id $routeT2Id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $natGateId

#associating public subnet to route table1

aws_assoId1=$(aws ec2 associate-route-table --route-table-id $routeT1Id --subnet-id $subnetId1Zone1)
assoId1Z1=$(echo "$aws_assoId1" | /usr/bin/jq '.AssociationId' | tr -d '"')
echo $assoId1Z1

#associating private subnets to route table2

aws_assoId2=$(aws ec2 associate-route-table --route-table-id $routeT2Id --subnet-id $subnetId2Zone1)
assoId2Z1=$(echo "$aws_assoId2" | /usr/bin/jq '.AssociationId' | tr -d '"')
echo $assoId2Z1

aws_assoId2=$(aws ec2 associate-route-table --route-table-id $routeT2Id --subnet-id $subnetId2Zone2)
assoId2Z2=$(echo "$aws_assoId2" | /usr/bin/jq '.AssociationId' | tr -d '"')
echo $assoId2Z2

aws_assoId2=$(aws ec2 associate-route-table --route-table-id $routeT2Id --subnet-id $subnetId2Zone3)
assoId2Z3=$(echo "$aws_assoId2" | /usr/bin/jq '.AssociationId' | tr -d '"')
echo $assoId2Z3

#adding all ids to a file
touch data.txt

echo "$vpcId $name $region $cidr $subnetId1Zone1 $subnetId2Zone1 $subnetId3Zone1 $subnetId1Zone2 $subnetId2Zone2 $subnetId1Zone3 $subnetId2Zone3 $igId $eipAllocId $natGateId $routeT1Id $routeT2Id $assotd1Z1 $assoId2Z1 $assoId2Z2 $assoID2Z3 " > data.txt

echo ”VPC created successfully..”
