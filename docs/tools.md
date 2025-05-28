# Tool Reference

This document provides detailed information about all tools and software installed by the Ubuntu ISO customizer.

## Development Tools

### Build Tools

#### build-essential
**Purpose:** Essential compilation tools for building software from source  
**Includes:** gcc, g++, make, libc6-dev, dpkg-dev  
**Usage:** Automatically used when compiling C/C++ programs  
**Commands:**
```bash
gcc -o program program.c
make
```

#### cmake
**Purpose:** Cross-platform build system generator  
**Usage:** Building complex C/C++ projects  
**Commands:**
```bash
cmake .
make
```

### Version Control

#### Git
**Purpose:** Distributed version control system  
**Features:** Full Git functionality with LFS support  
**Configuration:** Pre-configured with useful aliases and settings  
**Commands:**
```bash
git clone <repository>
git add .
git commit -m "message"
git push
```

**Installed Aliases:**
- `gs` - git status
- `ga` - git add
- `gc` - git commit
- `gp` - git push
- `gl` - git pull
- `glog` - formatted log output

### Programming Languages

#### Python 3
**Purpose:** Modern Python programming language  
**Includes:** python3, pip3, venv, development headers  
**Virtual Environment:** Pre-configured with virtualenv and pipenv  
**Common Packages:** pandas, numpy, matplotlib, requests, flask, django

**Usage:**
```bash
python3 --version
pip3 install package_name
python3 -m venv myproject
source myproject/bin/activate
```

#### Node.js
**Purpose:** JavaScript runtime for server-side development  
**Version:** Latest LTS version  
**Package Managers:** npm, yarn  
**Global Packages:** TypeScript, Angular CLI, Create React App, Vue CLI

**Usage:**
```bash
node --version
npm --version
npm install -g package_name
npx create-react-app myapp
```

### Text Editors and IDEs

#### Visual Studio Code
**Purpose:** Modern code editor with extensive plugin ecosystem  
**Features:** IntelliSense, debugging, Git integration, extensions  
**Launch:** `code` command or application menu

**Pre-configured Extensions:**
- Python support
- TypeScript support
- Docker integration
- JSON formatting

#### Vim
**Purpose:** Advanced text editor  
**Configuration:** Custom .vimrc with syntax highlighting and useful settings  
**Usage:**
```bash
vim filename
# Basic commands: i (insert), :w (save), :q (quit), :wq (save and quit)
```

#### Nano
**Purpose:** Simple command-line text editor  
**Usage:**
```bash
nano filename
# Ctrl+X to exit, Ctrl+O to save
```

## Containerization

### Docker
**Purpose:** Container platform for application deployment  
**Components:** Docker CE, Docker CLI, containerd, Docker Compose  
**User Setup:** Current user added to docker group (requires logout/login)

**Usage:**
```bash
docker --version
docker run hello-world
docker-compose up
```

**Useful Aliases:**
- `dps` - docker ps
- `di` - docker images
- `dex` - docker exec -it
- `drun` - docker run -it --rm

### Docker Compose
**Purpose:** Multi-container Docker application management  
**Usage:**
```bash
docker-compose up -d
docker-compose down
docker-compose logs
```

## System Utilities

### Monitoring Tools

#### htop
**Purpose:** Interactive process viewer  
**Features:** Real-time system monitoring, process management  
**Usage:**
```bash
htop
# F10 to quit, F9 to kill process, F6 to sort
```

#### tree
**Purpose:** Directory structure visualization  
**Usage:**
```bash
tree
tree -a  # Show hidden files
tree -L 2  # Limit depth to 2 levels
```

#### jq
**Purpose:** JSON processor and formatter  
**Usage:**
```bash
echo '{"name":"John","age":30}' | jq .
curl -s api.example.com/data | jq '.results[]'
```

### Network Tools

#### curl
**Purpose:** Command-line HTTP client  
**Usage:**
```bash
curl https://api.example.com
curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' url
```

#### wget
**Purpose:** File downloader  
**Usage:**
```bash
wget https://example.com/file.zip
wget -r -np https://example.com/directory/
```

#### net-tools
**Purpose:** Network configuration utilities  
**Includes:** netstat, ifconfig, route, arp  
**Usage:**
```bash
netstat -tuln  # Show listening ports
ifconfig       # Network interface configuration
```

### File Management

#### zip/unzip
**Purpose:** Archive creation and extraction  
**Usage:**
```bash
zip -r archive.zip directory/
unzip archive.zip
```

#### rsync
**Purpose:** File synchronization and backup  
**Usage:**
```bash
rsync -av source/ destination/
rsync -av --delete source/ destination/  # Mirror sync
```

## Security Tools

### UFW (Uncomplicated Firewall)
**Purpose:** Simple firewall management  
**Configuration:** Pre-configured with secure defaults  
**Usage:**
```bash
sudo ufw status
sudo ufw allow 22/tcp
sudo ufw deny 80/tcp
sudo ufw enable
```

### Fail2ban
**Purpose:** Intrusion prevention system  
**Features:** Automatically blocks malicious IP addresses  
**Configuration:** Monitors SSH attempts by default

### OpenSSH Server
**Purpose:** Secure remote access  
**Configuration:** Hardened settings, root login disabled  
**Usage:**
```bash
ssh user@hostname
scp file.txt user@hostname:/path/
```

## Development Frameworks

### Web Development

#### Angular CLI
**Purpose:** Angular application scaffolding and development  
**Usage:**
```bash
ng new my-app
ng serve
ng build --prod
```

#### Create React App
**Purpose:** React application boilerplate  
**Usage:**
```bash
npx create-react-app my-app
cd my-app
npm start
```

#### Vue CLI
**Purpose:** Vue.js application development  
**Usage:**
```bash
vue create my-project
vue serve
vue build
```

### Python Frameworks

#### Flask
**Purpose:** Lightweight web framework  
**Usage:**
```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World!'

if __name__ == '__main__':
    app.run(debug=True)
```

#### Django
**Purpose:** Full-featured web framework  
**Usage:**
```bash
django-admin startproject myproject
cd myproject
python manage.py runserver
```

## Package Managers

### APT (Advanced Package Tool)
**Purpose:** System package management  
**Usage:**
```bash
sudo apt update
sudo apt install package_name
sudo apt remove package_name
sudo apt autoremove
```

### pip3
**Purpose:** Python package installer  
**Usage:**
```bash
pip3 install package_name
pip3 list
pip3 freeze > requirements.txt
pip3 install -r requirements.txt
```

### npm
**Purpose:** Node.js package manager  
**Usage:**
```bash
npm install package_name
npm install -g package_name  # Global installation
npm list
npm outdated
```

### yarn
**Purpose:** Alternative Node.js package manager  
**Features:** Faster, more secure than npm  
**Usage:**
```bash
yarn add package_name
yarn global add package_name
yarn list
yarn upgrade
```

## Useful Aliases and Functions

### Navigation Aliases
- `ll` - ls -alF (detailed list)
- `la` - ls -A (all files)
- `..` - cd .. (up one directory)
- `...` - cd ../.. (up two directories)

### Git Aliases
- `gs` - git status
- `glog` - git log --oneline --graph --all --decorate

### System Aliases
- `update` - sudo apt update && sudo apt upgrade
- `install` - sudo apt install
- `ports` - netstat -tuln
- `myip` - curl -s ipinfo.io/ip

### Custom Functions

#### extract()
**Purpose:** Universal archive extractor  
**Usage:**
```bash
extract archive.tar.gz
extract file.zip
extract document.rar
```

#### mkcd()
**Purpose:** Create directory and enter it  
**Usage:**
```bash
mkcd new-project
```

#### backup()
**Purpose:** Quick file/directory backup  
**Usage:**
```bash
backup important-file.txt
# Creates: important-file.txt.backup.20250527-143022
```

#### sysinfo()
**Purpose:** Display system information summary  
**Usage:**
```bash
sysinfo
# Shows: hostname, uptime, memory, disk usage, CPU info
```

## Configuration Files

### Git Configuration
**Location:** ~/.gitconfig  
**Features:** User info, aliases, color schemes, editor preferences

### Bash Configuration
**Location:** ~/.bashrc_additions  
**Features:** Custom aliases, functions, environment variables, history settings

### Vim Configuration
**Location:** ~/.vimrc  
**Features:** Syntax highlighting, indentation, search settings

## Troubleshooting

### Common Issues

**Command not found:**
```bash
# Check if package is installed
dpkg -l | grep package_name

# Find which package provides a command
apt search command_name
```

**Permission denied:**
```bash
# Check file permissions
ls -la filename

# Make script executable
chmod +x script.sh

# Check sudo access
sudo -l
```

**Service not running:**
```bash
# Check service status
systemctl status service_name

# Start service
sudo systemctl start service_name

# Enable service at boot
sudo systemctl enable service_name
```

### Log Files

- System logs: `/var/log/syslog`
- Installation logs: `/var/log/post-install-*.log`
- Service logs: `journalctl -u service_name`
- Application logs: Varies by application

### Getting Help

**Man pages:**
```bash
man command_name
man -k keyword  # Search man pages
```

**Package information:**
```bash
apt info package_name
dpkg -L package_name  # List files in package
```

**Online resources:**
- Official documentation for each tool
- Stack Overflow for specific issues
- GitHub repositories for open-source tools

This reference guide covers the core tools included in the custom Ubuntu installation. Each tool has extensive documentation available through man pages, official websites, and community resources.
