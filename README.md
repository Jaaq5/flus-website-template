# flus-website-template

Template repo to flus website

# To get started, clone this repository using the command below:

```bash
git clone https://github.com/Jaaq5/flus-website-template.git
```

# Configure private

```bash
cp prod-environment/ubuntu-24-04/private/ssh_ip_ranges.example.sh prod-environment/ubuntu-24-04/private/ssh_ip_ranges.sh
```

```bash
nano prod-environment/ubuntu-24-04/private/ssh_ip_ranges.sh
```

```bash
cp prod-environment/ubuntu-24-04/private/jail.example.local prod-environment/ubuntu-24-04/private/jail.local
```

```bash
nano prod-environment/ubuntu-24-04/private/jail.local
```

# Use this when conecting to server:

export TERM=xterm-256color

# To fix ipset not reset

sudo systemctl stop firewalld
sudo rm /etc/firewalld/ipsets/sshrange.xml
sudo nano /etc/firewalld/zones/public.xml
Delete ipset rule
sudo systemctl start firewalld

# To see fail2ban logs

```bash
cat /var/log/fail2ban.log
```

```bash
tail -f /var/log/fail2ban.log
```

sudo fail2ban-client status sshd

# UU

sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

// Dirección de correo del destinatario
Unattended-Upgrade::Mail "tu@correo.com";

// ¿Cuándo enviar correo?
// - "on-change": solo si se instalan paquetes.
// - "only-on-error": solo si falla.
// - "always": siempre, incluso sin paquetes instalados.
Unattended-Upgrade::MailReport "only-on-error";

// Opcional: puedes definir el remitente
Unattended-Upgrade::Sender "failures@mi-servidor.local";

sudo unattended-upgrades --dry-run -d

sudo sed -i 's/only-on-error/always/' /etc/apt/apt.conf.d/50unattended-upgrades
sudo unattended-upgrades -v
