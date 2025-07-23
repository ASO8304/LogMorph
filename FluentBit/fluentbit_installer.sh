curl -s https://packages.fluentbit.io/fluentbit.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/fluentbit.gpg
echo "deb https://packages.fluentbit.io/ubuntu/jammy jammy main" | sudo tee /etc/apt/sources.list.d/fluentbit.list
sudo apt update
sudo apt install fluent-bit