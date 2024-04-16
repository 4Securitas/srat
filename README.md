# S.R.A.T.
ACSIA SOS - Sigma Rules Automated Tool

This tool has been created by the Dectar support team to allow our on-premise customers to easily create, modify or delete Sigma rules inside our tool ACSIA SOS.

## IMPORTANT: Proceed with caution!

Wrongly modified or wrong Sigma Rules can heavily impact the operations of ACSIA SOS, before proceeding further is always adviced to check with our support team.
If you want to push a new sigma rule or modify an existing one you will need to manually change the file sigma.yaml present in the srat folder!

## Installing dependencies and usage

At the moment the script is purely in bash and it will not require any additional package so there is no installation to be performed.
To use is follow the steps below:

```sh
# Download the script inside ACSIA SOS
git clone https://github.com/4Securitas/srat

# Change directory
cd srat/

# Change permissions
chmod +x srat.sh

# Execute the script and enjoy
./srat.sh
```
