## Description
This repo is meant as a starting point to demonstrate the ability to manipulate input data into a multi-site F5 GTM/LTM deployment using Ansible. The idea is to provide **Maximum Output** with **Minimum Input**. The data structure may not fit your needs exactly but can be customized to fit the standards of your organization. Given the modular nature of ansible, it would be fairly straight forward to add a section for DNS or AFM creation as part of the flow.

#### Input

This input represents an app that contains 1 GSLB Record and 3 LTM VIPs below it (one being fronted by an AWS EIP).

```yaml
app_name: example1
gslb_domain: gslb.example.com
app_locations:
  - datacenter_name: Zone1
    vip_address: 10.1.1.10:80
    pool_members:
      - pm: 172.16.1.100:8001
        pr: 10
  - datacenter_name: Zone2
    vip_address: 10.2.1.10:80
    pool_members:
      - pm: 172.16.2.100:8001
        pr: 10
  - datacenter_name: aws
    vip_address: 10.3.1.10:80
    eip:
      vip_address: <public-ElasticIP>:80
      datacenter_name: aws_eips
    pool_members:
      - pm: 10.1.0.217:8001
        pr: 10
      - pm: 10.1.0.217:8002
        pr: 7
```

#### Output
With the above input, you will get the following objects:

* WIDE-IP: ``example1.gslb.example.com``
  * WIP-Pool: ``example1.gslb.example.com``
    * Zone1 VIP with members
    * Zone2 VIP with members
    * AWS VIP with members
      * Elastic IP fronting the VIP as a dependency

## Example Environment
-  Ansible Host (device running ansible)
-  Zone1 BIG-IP LTM/AFM
-  Zone2 BIG-IP LTM/AFM
-  AWS BIG-IP LTM/GTM/AFM

##### Diagram
![alt text](files/f5_multisite_diagram.png)

Each BIG-IP has its base config setup (DNS, NTP, Auth, etc). The GTM has its listeners, datacenters, and remote BIG-IPs connected. The steps below will walk through provisioning this repo to use the environment above. Please insert your environment variables as needed.

## Core File Structure
    
```shell
├── app_templates           #Stores example Apps
├── files                   #External objects such as irules, policies, etc
├── host_vars               #A Folder for each Host in 'hosts'
│   ├── aws                 #Example host 'AWS'
│   │   ├── vars.yaml       #Vars and Provider for 'AWS'
│   │   └── vault.yaml      #Vault for AWS (password store)
│   ├── .....               #More host var folders
├── create_app.yaml         #Primary playbook which calls LTM, GTM, etc...
├── gtm_tasks.yaml          #GTM tasks
└── ltm_tasks.yaml          #LTM tasks
```


## Setup
1. Edit the **hosts** file.
    1. In our example we have 1 item under GTM and 3 under LTM. The do not have to be reachable via the name below.
    1. Ensure that localhost is pointing to the correct python executable.
    ```ini
    # hosts file
    localhost ansible_python_interpreter=/usr/bin/python

    [LTM]
    Zone1
    Zone2
    aws

    [GTM]
    aws
    ```
1. Create 'host_vars' directory structure for each host added. In the example we       will have 1 host_var folder for Zone1,Zone2, and aws. You can rename/modify         existing folders or delete and recreate. [More info on Inventory and vars](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

    ```
        ├── host_vars               #A Folder for each Host in 'hosts'
        │   ├── aws                 #Example host 'AWS'
        │   │   ├── vars.yaml       #Vars and Provider for 'AWS'
        │   │   └── vault.yaml      #Vault for AWS (password store)
    ```
    1. Below are the examples for **vars.yaml** and **vault.yaml** for the **aws** folder.
    1. **vars.yaml** is primary storing the **provider** or connection information for the host.

        ```yaml
        #vars.yaml
        provider:
            server: 10.192.75.66
            user: admin
            password: "{{ vault_password }}"
            validate_certs: no
            server_port: 443
        ```
    1. **vault.yaml** stores the password for connecting to the BIG-IP
        ```yaml
        #vault.yaml
        vault_password: admin
        ```
    1. Encrypt the vault file for each host using: `ansible-vault encrypt vault.yaml`. It will ask you to set a password to decrypt the file for use within a playbook. [More info on vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
    1. Repeat the above steps for each host that was added to the **hosts** inventory file.


## Creating an end-to-end App

1. Edit the existing file **App1.yaml** or create an app template file within **app_templates**. The example is prefilled but does not have IPs specific to your environment.

1. Run the following command from the root directory where **App1.yaml** is your edited variable file.
    ```shell
    ansible-playbook -i hosts create_app.yaml -e "@app_templates/App1.yaml" --ask-vault-pass
    ```

   1. The playbook being run is very simple in itself as its purpose is to call in the specific playboosk for LTM, GTM, and anything else added in the future.

   ```yaml
    - name: Create LTM/GTM Config
      hosts: localhost
      gather_facts: false
      connection: local
  
      tasks:
  
          - include_tasks: ltm_tasks.yaml
            loop: "{{ app_locations }}"
            loop_control:
                loop_var: loc
  
          - include_tasks: gtm_tasks.yaml
   ```
1. Verify the configuration has been placed on the proper BIG-IPs.

## Conclusion

As mentioned before, this is meant to be an example of what is possible. Please add/remove parameters from the templates and playbooks to add value to your specific needs.