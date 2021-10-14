# Hashicorp Nomad Cluster with TLS enabled and a self-signed certificate by Ansible

## **Requirements**

- [x] Python 2.7+
- [x] Ansible 2.9+
- [x] Internet access
- [3] Servers # This is a list of hardware tested on a virtual machine
  - [x] Hardware:
    - [x] 2 vCPU
    - [x] 2 GB RAM
    - [x] 2 disk, Operating System (sda) and Data disk (sdb)

## **Pre tasks**

- Clone this repository:

```shell
git clone https://github.com/fabianoflorentino/nomad.git
```

- Create new inventory:

```shell
cp -rfp inventories/sample inventories/<YOUR INVENTORY>
```

- Edit inventory with server information:

| **Variable** | **Description** |
| --- | --- |
| datacenter | name of the datacenter used on configuration file nomad.hcl|
| region | name of the region used on configuration file nomad.hcl|

```yaml
---
all:
  vars:
    datacenter: ""
    region: ""
  children:
    server:
      hosts:
    client:
      hosts:
```

Ex.

```yaml
---
all:
  vars:
    datacenter: "onpremise"
    region: "sao01"
  hosts:
    nomad-server-1.lab.local:
      ansible_host: 172.16.252.21
    nomad-server-2.lab.local:
      ansible_host: 172.16.252.22
    nomad-server-3.lab.local:
      ansible_host: 172.16.252.23
    nomad-worker-1.lab.local:
      ansible_host: 172.16.252.41
    nomad-worker-2.lab.local:
      ansible_host: 172.16.252.42
    nomad-worker-3.lab.local:
      ansible_host: 172.16.252.43
  children:
    server:
      hosts:
        nomad-server-1.lab.local:
        nomad-server-2.lab.local:
        nomad-server-3.lab.local:
    client:
      hosts:
        nomad-worker-1.lab.local:
        nomad-worker-2.lab.local:
        nomad-worker-3.lab.local:
```

<details>
  <summary><b>Server Configuration</b> <em>(Details)</em></summary>

- Insert your information on [**./role/server/vars/main.yml**](./role/server/vars/main.yml):

This variables are used on configuration file [**./role/server/templates/nomad.hcl.j2**](./role/server/templates/nomad.hcl.j2).

| **Variables** | **Description** |
| --- | --- |
| data_dir | directory where nomad stores data |
| bind_addr | IP address to bind nomad to |
| bind_port | port to bind nomad to |
| log_level | log level |
| server_enable | enable nomad server |
| server_client | enable nomad client |
| bootstrap_expect | number of servers to expect |
| retry_max | max number of retries |
| retry_interval | retry interval |

Ex.

```yaml
---
data_dir: "/nomad/data"
bind_addr: "0.0.0.0"
bind_port: "4648"
log_level: "INFO"
server_enable: "true"
client_enable: "false"
bootstrap_expect: "3"
retry_max: 3
retry_interval: 5s

tls_http: "true"
tls_rpc: "true"
verify_server_hostname: "true"
verify_https_client: "false"

path_certificate: "/nomad/data/certificates/ssl"
ca_file: "{{ path_certificate }}/ca.pem"
cert_file: "{{ path_certificate }}/server.pem"
key_file: "{{ path_certificate }}/server.key"
```

### **Template**

Documentation: [**https://www.nomadproject.io/docs/configuration/server**](https://www.nomadproject.io/docs/configuration/server)

```jinja
data_dir   = "{{ data_dir }}"
bind_addr  = "{{ bind_addr }}"
log_level  = "{{ log_level }}"
datacenter = "{{ datacenter }}"
region     = "{{ region }}"

server {
    enabled          = {{ server_enabled }}
    bootstrap_expect = {{ bootstrap_expect }}
    server_join {
        retry_join = [
    {% for item in groups['server'] %}
        "{{ hostvars[item]['inventory_hostname'] }}:{{ bind_port }}",
    {% endfor %}
        ]
        retry_max      = {{ retry_max }}
        retry_interval = "{{ retry_interval }}"
    }
}

tls {
    http      = {{ tls_http }}
    rpc       = {{ tls_rpc }}
    ca_file   = "{{ ca_file }}"
    cert_file = "{{ cert_file }}"
    key_file  = "{{ key_file }}"

    verify_server_hostname = {{ verify_server_hostname }}
    verify_https_client    = {{ verify_https_client }}

}

client {
    enabled = {{ client_enabled }}
}
```

### **Execute**

### **Description**

| **Roles** | **Description** |
| --- | --- |
| disk | create a disk for nomad |
| common | common tasks |
| openssl | generate self-signed certificates for servers and clients |
| server | create cluster of nomad |

**OBS**: Require aditional disk. [**./roles/disk/vars/main.yml**](./roles/disk/vars/main.yml)

```yaml
---
device: "/dev/sdb"
dev_size: "90g"
vg_name: "nomad"
lv_name: "data"
logical_device: "/dev/nomad/data"
dir_mount:
  - "/nomad"
  - "/nomad/data"
path_mount: "/nomad/data"
```

- [x] [**disk**](./roles/disk)
  - [x] Enable LVM 2
  - [x] Create new Volume Group
  - [x] Create new Logical Volume
  - [x] Create a filesystem
  - [x] Directory to mount
  - [x] Mount new directory

- [x] [**common**](./roles/common)
  - [x] Update instance
  - [x] Common Packages
  - [x] Install Pip Modules
  - [x] Configuration NTP Service
  - [x] Update the hostsname
  - [x] Update /etc/hosts
  - [x] Enable Services
  - [x] Disable Services
  - [x] Disable SELinux

- [x] [**openssl**](./roles/openssl)
  - [x] Openssl Install and Update
  - [x] "Check if OpenSSL is installed"
  - [x] Directory to CA
  - [x] CA and Server Certificates
  - [x] Create private key with password protection
  - [x] Create certificate signing request (CSR) for CA certificate
  - [x] Create self-signed CA certificate from CSR
  - [x] Create private key for new certificate on "{{ groups['server'][0] }}"
  - [x] Create certificate signing request (CSR) for new certificate
  - [x] Sign certificate with our CA
  - [x] Write certificate file on "{{ groups['server'][0] }}"
  - [x] Create private key for new certificate on "{{ groups['server'][0] }}"
  - [x] Create certificate signing request (CSR) for new certificate
  - [x] Sign certificate with our CA
  - [x] Write certificate file on "{{ groups['server'][0] }}"
  - [x] Fetch certificate file from remote host
  - [x] Copy server certificate file to hosts
  - [x] Client Certificate
  - [x] Fetch certificate file from remote host
  - [x] Copy client certificate file to hosts

- [x] [**server**](./roles/server)
  - [x] Add Hashicorp Repo
  - [x] Get stats of the Nomad Download
  - [x] Copy the Nomad configuration file
  - [x] "Ajust Certificates Permission"
  - [x] "Ajust Directory Permission"
  - [x] Start the Nomad service

### **run**

```shell
ansible-playbook -i inventories/<YOUR INVENTORY>/hosts.yml server.yml
```

</details>

## **Client Configuration**
