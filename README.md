# VPC Infrastructure with Terraform

This Terraform project creates a secure AWS VPC infrastructure with public and private subnets, along with EC2 instances for demonstration purposes. The setup includes a bastion host for secure access to private resources.

## Architecture

The infrastructure consists of:

- **VPC**: A virtual private cloud with CIDR `10.0.0.0/16`
- **Subnets**:
  - Public subnet (`10.0.1.0/24`) with internet access
  - Private subnet (`10.0.2.0/24`) without direct internet access
- **Internet Gateway**: Provides internet connectivity for the public subnet
- **Route Tables**: Separate routing for public and private subnets
- **Security Groups**:
  - Public SG: Allows SSH (22) and HTTP (80) from anywhere
  - Private SG: Allows SSH only from the public security group
- **EC2 Instances**:
  - Public EC2 instance in the public subnet
  - Bastion host in the public subnet for secure access
  - Private EC2 instance in the private subnet
- **SSH Key Pair**: Automatically generated RSA key pair for instance access

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate permissions
- AWS profile named "abir" (or update `terraform.tfvars` accordingly)
- SSH client for connecting to instances

## Usage

1. **Clone the repository** (if applicable) and navigate to the project directory.

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the infrastructure**:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm.

5. **Access the instances**:
   - Use the bastion host public IP to SSH into the private instance:
     ```bash
     ssh -i generated-key.pem ubuntu@<bastion-public-ip>
     ```
     Then from the bastion:
     ```bash
     ssh -i generated-key.pem ubuntu@<private-ec2-private-ip>
     ```
   - Direct access to public EC2:
     ```bash
     ssh -i generated-key.pem ubuntu@<public-ec2-public-ip>
     ```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-north-1` | AWS region for deployment |
| `aws_profile` | `abir` | AWS CLI profile name |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `public_subnet_cidr` | `10.0.1.0/24` | Public subnet CIDR |
| `private_subnet_cidr` | `10.0.2.0/24` | Private subnet CIDR |

## Outputs

After deployment, Terraform will output:

- `public_ec2_public_ip`: Public IP of the public EC2 instance
- `private_ec2_private_ip`: Private IP of the private EC2 instance
- `bastion_host_public_ip`: Public IP of the bastion host
- `private_key_path`: Path to the generated private key file

## Security Considerations

- The public security group allows SSH and HTTP from `0.0.0.0/0`. In production, restrict these to specific IP ranges.
- The generated private key is stored locally. Secure it appropriately.
- The private subnet has no internet access, ensuring isolation of sensitive resources.

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

## Notes

- All EC2 instances use the latest Ubuntu 22.04 LTS AMI.
- Instance type is set to `t3.micro` (free tier eligible).
- The private key file `generated-key.pem` is created in the project directory with permissions `0400`.